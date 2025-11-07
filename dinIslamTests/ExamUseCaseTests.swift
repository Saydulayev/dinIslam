import XCTest
@testable import dinIslam

final class ExamUseCaseTests: XCTestCase {
    private let sampleQuestion = Question(
        id: "q1",
        text: "Sample question",
        answers: [
            Answer(id: "a1", text: "Answer 1"),
            Answer(id: "a2", text: "Answer 2"),
            Answer(id: "a3", text: "Answer 3")
        ],
        correctIndex: 1,
        category: "General",
        difficulty: .medium
    )

    func testExamAnswerCorrectness() {
        let correctAnswer = ExamAnswer(
            questionId: sampleQuestion.id,
            selectedAnswerIndex: 1,
            correctAnswerIndex: 1
        )

        let incorrectAnswer = ExamAnswer(
            questionId: sampleQuestion.id,
            selectedAnswerIndex: 0,
            correctAnswerIndex: 1
        )

        let skippedAnswer = ExamAnswer(
            questionId: sampleQuestion.id,
            correctAnswerIndex: 1,
            isSkipped: true
        )

        let timeExpiredAnswer = ExamAnswer(
            questionId: sampleQuestion.id,
            selectedAnswerIndex: 1,
            correctAnswerIndex: 1,
            isTimeExpired: true
        )

        XCTAssertTrue(correctAnswer.isCorrect)
        XCTAssertFalse(incorrectAnswer.isCorrect)
        XCTAssertFalse(skippedAnswer.isCorrect)
        XCTAssertFalse(timeExpiredAnswer.isCorrect)
    }

    @MainActor
    func testCalculateExamResultUsesExamAnswerCorrectness() {
        let repository = StubQuestionsRepository(questions: [sampleQuestion])
        let useCase = ExamUseCase(
            questionsRepository: repository,
            examStatisticsManager: ExamStatisticsManager()
        )

        let answers: [String: ExamAnswer] = [
            sampleQuestion.id: ExamAnswer(
                questionId: sampleQuestion.id,
                selectedAnswerIndex: 1,
                correctAnswerIndex: 1
            )
        ]

        let result = useCase.calculateExamResult(
            questions: [sampleQuestion],
            answers: answers,
            configuration: .default,
            totalTimeSpent: 30
        )

        XCTAssertEqual(result.correctAnswers, 1)
        XCTAssertEqual(result.incorrectAnswers, 0)
        XCTAssertEqual(result.skippedQuestions, 0)
    }
}

private final class StubQuestionsRepository: QuestionsRepositoryProtocol {
    private let questions: [Question]

    init(questions: [Question]) {
        self.questions = questions
    }

    func loadQuestions(language: String) async throws -> [Question] {
        questions
    }
}

