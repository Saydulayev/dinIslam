//
//  ExamViewModelTests.swift
//  dinIslamTests
//

import SwiftUI
import XCTest
@testable import dinIslam

@MainActor
final class ExamViewModelTests: XCTestCase {

    private let statisticsKey = "ExamStatistics"
    private var savedStatistics: Data?

    private var useCase: MockExamUseCase!
    private var timer: ManualExamTimer!
    private var recorder: SpyStatisticsRecorder!
    private var achievements: SpyAchievementChecker!
    private var viewModel: ExamViewModel!

    override func setUp() async throws {
        // ExamStatisticsManager пишет в UserDefaults.standard — сохраняем и восстанавливаем
        savedStatistics = UserDefaults.standard.data(forKey: statisticsKey)
        useCase = MockExamUseCase()
        timer = ManualExamTimer()
        recorder = SpyStatisticsRecorder()
        achievements = SpyAchievementChecker()
        viewModel = ExamViewModel(
            examUseCase: useCase,
            examStatisticsManager: ExamStatisticsManager(),
            statisticsRecorder: recorder,
            achievementChecker: achievements,
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

    func testTimeUpOnLastQuestion_withoutSkipped_finishesExam() async throws {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        viewModel.selectAnswer(at: 0)
        try await Task.sleep(for: .seconds(1.7))

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

    /// После ответа уже идёт переход к следующему вопросу — пауза в этот момент не срабатывает
    func testPauseRightAfterAnswer_isIgnored_andExamAdvances() async throws {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        XCTAssertTrue(viewModel.canPause)

        viewModel.selectAnswer(at: 0)
        XCTAssertFalse(viewModel.canPause)
        viewModel.pauseExam()
        XCTAssertEqual(viewModel.state, .active(.playing))

        try await Task.sleep(for: .seconds(1.8))

        XCTAssertEqual(viewModel.currentQuestionIndex, 1)
        XCTAssertEqual(viewModel.state, .active(.playing))
        XCTAssertTrue(timer.isTimerActive)
        XCTAssertTrue(viewModel.canPause)
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

    // MARK: - Progress

    func testProgress_reachesFullAfterLastAnswer() async {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        XCTAssertEqual(viewModel.progress, 0)

        viewModel.skipQuestion()
        XCTAssertEqual(viewModel.progress, 0.5)

        viewModel.selectAnswer(at: 0)
        XCTAssertEqual(viewModel.progress, 1)
    }

    // MARK: - Return to skipped

    func testLastQuestion_withSkipped_offersToReturn() async {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        viewModel.skipQuestion()
        viewModel.skipQuestion()

        XCTAssertEqual(viewModel.state, .active(.skippedPrompt))
        XCTAssertEqual(viewModel.skippedQuestionIndices, [0, 1])
        XCTAssertEqual(useCase.calculateResultCallCount, 0)
        XCTAssertFalse(timer.isTimerActive)
    }

    func testReturnToSkipped_answerAll_thenFinishes() async throws {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        viewModel.skipQuestion()
        viewModel.skipQuestion()

        viewModel.returnToSkipped()
        XCTAssertEqual(viewModel.state, .active(.playing))
        XCTAssertTrue(viewModel.isReturningToSkipped)
        XCTAssertEqual(viewModel.currentQuestionIndex, 0)
        XCTAssertNil(viewModel.answers["q1"], "Пропуск снимается, на вопрос можно ответить")
        XCTAssertTrue(timer.isTimerActive)

        viewModel.selectAnswer(at: 0)
        try await Task.sleep(for: .seconds(1.7))
        XCTAssertEqual(viewModel.currentQuestionIndex, 1)

        viewModel.selectAnswer(at: 0)
        try await Task.sleep(for: .seconds(1.7))
        XCTAssertEqual(viewModel.state, .completed(.finished))
        XCTAssertEqual(viewModel.answers["q1"]?.isCorrect, true)
        XCTAssertEqual(viewModel.answers["q2"]?.isCorrect, true)
    }

    func testReturnToSkipped_skipAgain_offersAgain() async {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        viewModel.skipQuestion()
        viewModel.skipQuestion()

        viewModel.returnToSkipped()
        viewModel.skipQuestion()
        viewModel.skipQuestion()

        XCTAssertEqual(viewModel.state, .active(.skippedPrompt))
        XCTAssertEqual(viewModel.skippedQuestionIndices, [0, 1])
    }

    /// К вопросу, на котором вышло время, не вернуться
    func testTimeExpiredQuestion_isNotOfferedAgain() async throws {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        timer.fireTimeUp()
        try await Task.sleep(for: .seconds(1.7))
        viewModel.skipQuestion()

        XCTAssertEqual(viewModel.state, .active(.skippedPrompt))
        XCTAssertEqual(viewModel.skippedQuestionIndices, [1])

        viewModel.returnToSkipped()
        XCTAssertEqual(viewModel.currentQuestionIndex, 1)
    }

    func testFinishFromPrompt_recordsSkippedAsMistakes() async {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        viewModel.skipQuestion()
        viewModel.skipQuestion()

        viewModel.finishExam()

        XCTAssertEqual(viewModel.state, .completed(.finished))
        XCTAssertEqual(recorder.summaries.first?.outcomes.map(\.isCorrect), [false, false])
    }

    // MARK: - Recording answers

    /// Ответы экзамена попадают в общую статистику; пропуск — неверный ответ
    func testFinish_recordsAnswers_skipCountsAsMistake() async {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        viewModel.skipQuestion()
        viewModel.selectAnswer(at: 0)
        viewModel.finishExam()

        XCTAssertEqual(recorder.summaries.count, 1)
        let summary = recorder.summaries[0]
        XCTAssertFalse(summary.isComplete, "Экзамен не должен считаться пройденной викториной")
        XCTAssertEqual(summary.outcomes.map(\.questionId), ["q1", "q2"])
        XCTAssertEqual(summary.outcomes.map(\.isCorrect), [false, true])
        XCTAssertEqual(summary.correctAnswers, 1)
        XCTAssertEqual(achievements.checkCount, 1)
    }

    func testFinish_unansweredQuestionsAreNotRecorded() async {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        viewModel.selectAnswer(at: 1)
        viewModel.finishExam()

        XCTAssertEqual(recorder.summaries.first?.outcomes.map(\.questionId), ["q1"])
        XCTAssertEqual(recorder.summaries.first?.outcomes.first?.isCorrect, false)
    }

    func testFinishWithoutAnswers_recordsNothing() async {
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        viewModel.finishExam()

        XCTAssertTrue(recorder.summaries.isEmpty)
        XCTAssertEqual(achievements.checkCount, 0)
        XCTAssertNotNil(viewModel.examResult)
    }

    /// Достижения экзамена показываются на его экране, а не после следующей викторины
    func testFinish_takesNewAchievementsAndClearsSharedList() async {
        let achievement = Achievement(
            id: "scholar", title: "", description: "", icon: "", color: .blue, type: .scholar, requirement: 100
        )
        achievements.unlockOnCheck = [achievement]
        await viewModel.startExam(configuration: makeConfiguration(), language: "ru")
        viewModel.selectAnswer(at: 0)
        viewModel.finishExam()

        XCTAssertEqual(viewModel.newAchievements.map(\.id), ["scholar"])
        XCTAssertTrue(achievements.newAchievements.isEmpty)
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

private final class SpyStatisticsRecorder: QuizStatisticsRecording {
    private(set) var summaries: [QuizSessionSummary] = []
    var stats = UserStats()
    var dayStreak = 0

    func recordQuizSession(_ summary: QuizSessionSummary) {
        summaries.append(summary)
    }

    func registerDailyGoal() {}

    func getWrongQuestions(from allQuestions: [Question], scope: MistakesReviewScope) -> [Question] { [] }

    func recordReviewAnswers(_ answers: [String: Bool]) -> ReviewSessionSummary { ReviewSessionSummary() }
}

private final class SpyAchievementChecker: QuizAchievementChecking {
    private(set) var newAchievements: [Achievement] = []
    private(set) var checkCount = 0
    var unlockOnCheck: [Achievement] = []

    func checkAchievements(for stats: UserStats, dayStreak: Int, quizResult: QuizResult?) {
        checkCount += 1
        if !unlockOnCheck.isEmpty {
            newAchievements = unlockOnCheck
        }
    }

    func clearNewAchievements() {
        newAchievements.removeAll()
    }
}

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
    /// Время в тесте не идёт: остаток задаётся через timeRemaining
    let deadline: Date? = nil
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
