//
//  ExamViewModelTests.swift
//  dinIslamTests
//

import XCTest
@testable import dinIslam

@MainActor
final class ExamViewModelTests: XCTestCase {

    private let statisticsKey = "ExamStatistics"
    private var savedStatistics: Data?

    private var useCase: MockExamUseCase!
    private var timer: ManualExamTimer!
    private var viewModel: ExamViewModel!

    override func setUp() async throws {
        // ExamStatisticsManager пишет в UserDefaults.standard — сохраняем и восстанавливаем
        savedStatistics = UserDefaults.standard.data(forKey: statisticsKey)
        useCase = MockExamUseCase()
        timer = ManualExamTimer()
        viewModel = ExamViewModel(
            examUseCase: useCase,
            examStatisticsManager: ExamStatisticsManager(),
            feedbackProvider: SilentFeedbackProvider(),
            timerManager: timer
        )
    }

    override func tearDown() async throws {
        if let savedStatistics {
            UserDefaults.standard.set(savedStatistics, forKey: statisticsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: statisticsKey)
        }
    }

    // MARK: - Retake

    func testRetake_startsNewExamWithSameConfigurationAndLanguage() async {
        let configuration = makeConfiguration()
        await viewModel.startExam(configuration: configuration, language: "en")
        viewModel.finishExam()

        await viewModel.retake()

        XCTAssertEqual(useCase.startExamCalls.count, 2)
        XCTAssertEqual(useCase.startExamCalls.last?.configuration, configuration)
        XCTAssertEqual(useCase.startExamCalls.last?.language, "en")
        XCTAssertEqual(viewModel.state, .active(.playing))
        XCTAssertEqual(viewModel.currentQuestionIndex, 0)
        XCTAssertFalse(viewModel.questions.isEmpty)
        XCTAssertTrue(viewModel.answers.isEmpty)
        XCTAssertNil(viewModel.examResult)
    }

    // MARK: - Time up

    func testTimeUp_showsTimeUpThenNextQuestionIsAnswerable() async throws {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")

        timer.fireTimeUp()
        XCTAssertEqual(viewModel.state, .active(.timeUp))
        XCTAssertEqual(viewModel.answers["q1"]?.isTimeExpired, true)
        try await Task.sleep(for: .seconds(1.8))

        XCTAssertEqual(viewModel.state, .active(.playing))
        XCTAssertEqual(viewModel.currentQuestionIndex, 1)

        viewModel.selectAnswer(at: 0)
        XCTAssertNotNil(viewModel.answers["q2"]?.selectedAnswerIndex)
    }

    func testTimeUpOnLastQuestion_finishesExam() async throws {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        viewModel.skipQuestion()

        timer.fireTimeUp()
        try await Task.sleep(for: .seconds(1.8))

        XCTAssertEqual(viewModel.state, .completed(.finished))
        XCTAssertEqual(useCase.calculateResultCallCount, 1)
    }

    // MARK: - Pause

    func testPause_blocksAnswersUntilResume() async {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")

        viewModel.pauseExam()
        XCTAssertEqual(viewModel.state, .active(.paused))
        XCTAssertFalse(timer.isTimerActive)
        viewModel.selectAnswer(at: 0)
        XCTAssertNil(viewModel.answers["q1"])

        viewModel.resumeExam()
        XCTAssertEqual(viewModel.state, .active(.playing))
        XCTAssertTrue(timer.isTimerActive)
        viewModel.selectAnswer(at: 0)
        XCTAssertNotNil(viewModel.answers["q1"])
    }

    // MARK: - Timer display

    func testTimeRemainingFormatted_roundsUp() async {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")

        viewModel.timeRemaining = 28.95
        XCTAssertEqual(viewModel.timeRemainingFormatted, "00:29")
        viewModel.timeRemaining = 0.2
        XCTAssertEqual(viewModel.timeRemainingFormatted, "00:01")
        viewModel.timeRemaining = 0
        XCTAssertEqual(viewModel.timeRemainingFormatted, "00:00")
    }

    func testTimerUrgency_dependsOnTimeLimit() async {
        await viewModel.startExam(configuration: makeConfiguration(timePerQuestion: 15), language: "ru")

        viewModel.timeRemaining = 15
        XCTAssertEqual(viewModel.timerUrgency, .normal)
        viewModel.timeRemaining = 7
        XCTAssertEqual(viewModel.timerUrgency, .warning)
        viewModel.timeRemaining = 3
        XCTAssertEqual(viewModel.timerUrgency, .critical)

        await viewModel.startExam(configuration: makeConfiguration(timePerQuestion: 60), language: "ru")

        viewModel.timeRemaining = 25
        XCTAssertEqual(viewModel.timerUrgency, .normal)
        viewModel.timeRemaining = 20
        XCTAssertEqual(viewModel.timerUrgency, .warning)
        viewModel.timeRemaining = 10
        XCTAssertEqual(viewModel.timerUrgency, .critical)
    }

    // MARK: - Finish during pending transition

    func testFinishRightAfterAnswer_doesNotAdvanceOrFinishTwice() async throws { 
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")

        viewModel.selectAnswer(at: 0)
        viewModel.finishExam()
        try await Task.sleep(for: .seconds(1.7))

        XCTAssertEqual(useCase.calculateResultCallCount, 1)
        XCTAssertEqual(viewModel.currentQuestionIndex, 0)
        XCTAssertEqual(viewModel.state, .completed(.finished))
        XCTAssertFalse(timer.isTimerActive)
    }

    func testFinishRightAfterLastAnswer_calculatesResultOnce() async throws {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        viewModel.skipQuestion()

        viewModel.selectAnswer(at: 0)
        viewModel.finishExam()
        try await Task.sleep(for: .seconds(1.7))

        XCTAssertEqual(useCase.calculateResultCallCount, 1)
        XCTAssertEqual(viewModel.state, .completed(.finished))
    }

    // MARK: - Helpers

    private func makeConfiguration(timePerQuestion: TimeInterval = 30) -> ExamConfiguration {
        ExamConfiguration(
            timePerQuestion: timePerQuestion,
            totalQuestions: 2,
            allowSkip: true,
            showTimer: true
        )
    }
}

// MARK: - Test Doubles

private final class MockExamUseCase: ExamUseCaseProtocol {
    private(set) var startExamCalls: [(configuration: ExamConfiguration, language: String)] = []
    private(set) var calculateResultCallCount = 0

    let questions = ["q1", "q2"].map { id in
        Question(
            id: id,
            text: "Question \(id)",
            answers: [Answer(id: "\(id)-a", text: "A"), Answer(id: "\(id)-b", text: "B")],
            correctIndex: 0,
            category: "general",
            difficulty: .medium
        )
    }

    func startExam(configuration: ExamConfiguration, language: String) async throws -> [Question] {
        startExamCalls.append((configuration, language))
        return questions
    }

    func shuffleAnswers(for question: Question) -> Question { question }

    func calculateExamResult(
        questions: [Question],
        answers: [String: ExamAnswer],
        configuration: ExamConfiguration,
        totalTimeSpent: TimeInterval
    ) -> ExamResult {
        calculateResultCallCount += 1
        return ExamResult(
            totalQuestions: questions.count,
            answeredQuestions: answers.count,
            skippedQuestions: 0,
            correctAnswers: 0,
            incorrectAnswers: 0,
            timeExpiredQuestions: 0,
            totalTimeSpent: totalTimeSpent,
            averageTimePerQuestion: 0,
            percentage: 0,
            configuration: configuration,
            completedAt: Date()
        )
    }

    func loadExamQuestions(language: String, count: Int) async throws -> [Question] { questions }
}

/// Таймер, который срабатывает только по команде теста
@MainActor
private final class ManualExamTimer: ExamTimerManaging {
    var timeRemaining: TimeInterval = 0
    var isTimerActive = false
    var questionStartTime: Date?
    private var onTimeUp: (@MainActor () -> Void)?

    func startTimer(timeLimit: TimeInterval, onTimeUp: @escaping @MainActor () -> Void) {
        timeRemaining = timeLimit
        isTimerActive = true
        questionStartTime = Date()
        self.onTimeUp = onTimeUp
    }

    func stopTimer() {
        isTimerActive = false
        onTimeUp = nil
    }

    func fireTimeUp() {
        let callback = onTimeUp
        timeRemaining = 0
        isTimerActive = false
        callback?()
    }
}

private struct SilentFeedbackProvider: QuizFeedbackProviding {
    func answerSelected(isCorrect: Bool) {}
    func quizCompleted(success: Bool) {}
    func selectionChanged() {}
    func questionSkipped() {}
    func questionPaused() {}
    func questionResumed() {}
}
