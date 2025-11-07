@testable import dinIslam
import XCTest

@MainActor
final class ExamViewModelTests: XCTestCase {
    private var sampleQuestions: [Question] {
        [
            Question(
                id: "q1",
                text: "Question 1",
                answers: [
                    Answer(id: "a1", text: "A"),
                    Answer(id: "a2", text: "B"),
                    Answer(id: "a3", text: "C")
                ],
                correctIndex: 1,
                category: "General",
                difficulty: .medium
            ),
            Question(
                id: "q2",
                text: "Question 2",
                answers: [
                    Answer(id: "a4", text: "Option 1"),
                    Answer(id: "a5", text: "Option 2"),
                    Answer(id: "a6", text: "Option 3")
                ],
                correctIndex: 0,
                category: "General",
                difficulty: .medium
            )
        ]
    }
    
    func testSkipQuestionMarksAnswerAndAdvances() async {
        let useCase = MockExamUseCase(questions: sampleQuestions)
        let viewModel = ExamViewModel(
            examUseCase: useCase,
            examStatisticsManager: ExamStatisticsManager(),
            settingsManager: SettingsManager()
        )
        let configuration = ExamConfiguration(
            timePerQuestion: 60,
            totalQuestions: 2,
            allowSkip: true,
            showTimer: true,
            autoSubmit: true
        )
        await viewModel.startExam(configuration: configuration, language: "ru")
        XCTAssertEqual(viewModel.currentQuestion?.id, "q1")
        viewModel.skipQuestion()
        XCTAssertEqual(viewModel.currentQuestion?.id, "q2")
        let skippedAnswer = viewModel.answers["q1"]
        XCTAssertTrue(skippedAnswer?.isSkipped ?? false)
        XCTAssertTrue(skippedAnswer?.selectedAnswerIndex == nil)
    }
    
    func testFinishExamProducesResult() async {
        let useCase = MockExamUseCase(questions: sampleQuestions)
        let viewModel = ExamViewModel(
            examUseCase: useCase,
            examStatisticsManager: ExamStatisticsManager(),
            settingsManager: SettingsManager()
        )
        await viewModel.startExam(configuration: .default, language: "ru")
        viewModel.selectAnswer(at: 1) // correct for q1
        try? await Task.sleep(nanoseconds: 1_600_000_000)
        viewModel.selectAnswer(at: 0) // correct for q2
        try? await Task.sleep(nanoseconds: 1_600_000_000)
        viewModel.finishExam()
        let result = viewModel.examResult
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.correctAnswers, 2)
        XCTAssertEqual(result?.totalQuestions, 2)
    }
    
    func testResultSnapshotRoundTrip() {
        let quizResult = QuizResult(totalQuestions: 5, correctAnswers: 4, percentage: 80, timeSpent: 120)
        let snapshot = StartRoute.ResultSnapshot(from: quizResult)
        let restored = snapshot.makeQuizResult()
        XCTAssertEqual(restored.totalQuestions, quizResult.totalQuestions)
        XCTAssertEqual(restored.correctAnswers, quizResult.correctAnswers)
        XCTAssertEqual(restored.percentage, quizResult.percentage)
        XCTAssertEqual(restored.timeSpent, quizResult.timeSpent)
    }
}

// MARK: - Supporting Test Doubles

private final class MockExamUseCase: ExamUseCaseProtocol {
    private let questions: [Question]
    
    init(questions: [Question]) {
        self.questions = questions
    }
    
    func startExam(configuration: ExamConfiguration, language: String) async throws -> [Question] {
        Array(questions.prefix(configuration.totalQuestions))
    }
    
    func shuffleAnswers(for question: Question) -> Question { question }
    
    func calculateExamResult(
        questions: [Question],
        answers: [String: ExamAnswer],
        configuration: ExamConfiguration,
        totalTimeSpent: TimeInterval
    ) -> ExamResult {
        var correct = 0
        var incorrect = 0
        var skipped = 0
        var timeExpired = 0
        let answeredQuestions = answers
        for question in questions {
            guard let answer = answeredQuestions[question.id] else {
                skipped += 1
                continue
            }
            if answer.isTimeExpired {
                timeExpired += 1
                skipped += 1
            } else if answer.isSkipped {
                skipped += 1
            } else if answer.isCorrect {
                correct += 1
            } else {
                incorrect += 1
            }
        }
        let percentage = Double(correct) / Double(max(questions.count, 1)) * 100
        let averageTime = answers.isEmpty ? 0 : totalTimeSpent / Double(answers.count)
        return ExamResult(
            totalQuestions: questions.count,
            answeredQuestions: correct + incorrect,
            skippedQuestions: skipped,
            correctAnswers: correct,
            incorrectAnswers: incorrect,
            timeExpiredQuestions: timeExpired,
            totalTimeSpent: totalTimeSpent,
            averageTimePerQuestion: averageTime,
            percentage: percentage,
            configuration: configuration,
            completedAt: Date()
        )
    }
    
    func loadExamQuestions(language: String, count: Int) async throws -> [Question] {
        Array(questions.prefix(count))
    }
}
