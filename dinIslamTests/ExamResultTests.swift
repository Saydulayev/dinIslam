//
//  ExamResultTests.swift
//  dinIslamTests
//

import XCTest
@testable import dinIslam

final class ExamResultTests: XCTestCase {

    // MARK: - isPassed

    func testIsPassed_percentage70NoSkipped_returnsTrue() {
        let result = makeResult(percentage: 70.0, skippedQuestions: 0)
        XCTAssertTrue(result.isPassed)
    }

    func testIsPassed_percentage69NoSkipped_returnsFalse() {
        let result = makeResult(percentage: 69.0, skippedQuestions: 0)
        XCTAssertFalse(result.isPassed)
    }

    func testIsPassed_percentage70WithSkipped_returnsFalse() {
        let result = makeResult(percentage: 70.0, skippedQuestions: 1)
        XCTAssertFalse(result.isPassed)
    }

    func testIsPassed_highPercentageWithSkipped_returnsFalse() {
        let result = makeResult(percentage: 100.0, skippedQuestions: 2)
        XCTAssertFalse(result.isPassed)
    }

    func testIsPassed_percentageExactly70_noSkipped_returnsTrue() {
        let result = makeResult(percentage: 70.0, skippedQuestions: 0)
        XCTAssertTrue(result.isPassed)
    }

    // MARK: - Statistics

    /// Экзамен без единого ответа не даёт NaN в среднем балле (JSONEncoder не сохраняет NaN)
    @MainActor
    func testStatistics_examWithoutAnswers_averageScoreIsZero() throws {
        var statistics = ExamStatistics()
        statistics.updateStatistics(with: makeResult(percentage: 0, skippedQuestions: 20))

        XCTAssertEqual(statistics.averageScore, 0)
        XCTAssertNoThrow(try JSONEncoder().encode(statistics))
    }

    // MARK: - grade

    func testGrade_percentage90_returnsExcellent() {
        let result = makeResult(percentage: 90.0)
        XCTAssertEqual(result.grade, .excellent)
    }

    func testGrade_percentage100_returnsExcellent() {
        let result = makeResult(percentage: 100.0)
        XCTAssertEqual(result.grade, .excellent)
    }

    func testGrade_percentage85_returnsGood() {
        let result = makeResult(percentage: 85.0)
        XCTAssertEqual(result.grade, .good)
    }

    func testGrade_percentage80_returnsGood() {
        let result = makeResult(percentage: 80.0)
        XCTAssertEqual(result.grade, .good)
    }

    func testGrade_percentage79_returnsSatisfactory() {
        let result = makeResult(percentage: 79.0)
        XCTAssertEqual(result.grade, .satisfactory)
    }

    func testGrade_percentage70_returnsSatisfactory() {
        let result = makeResult(percentage: 70.0)
        XCTAssertEqual(result.grade, .satisfactory)
    }

    func testGrade_percentage50_returnsUnsatisfactory() {
        let result = makeResult(percentage: 50.0)
        XCTAssertEqual(result.grade, .unsatisfactory)
    }

    func testGrade_percentage69_returnsUnsatisfactory() {
        let result = makeResult(percentage: 69.0)
        XCTAssertEqual(result.grade, .unsatisfactory)
    }

    // MARK: - Helpers

    private func makeResult(
        percentage: Double,
        skippedQuestions: Int = 0,
        totalQuestions: Int = 20
    ) -> ExamResult {
        let answered = totalQuestions - skippedQuestions
        let correct = Int(round(percentage / 100.0 * Double(totalQuestions)))
        let incorrect = max(0, answered - correct)
        return ExamResult(
            totalQuestions: totalQuestions,
            answeredQuestions: answered,
            skippedQuestions: skippedQuestions,
            correctAnswers: correct,
            incorrectAnswers: incorrect,
            timeExpiredQuestions: 0,
            totalTimeSpent: 0,
            averageTimePerQuestion: 0,
            percentage: percentage,
            configuration: .default,
            completedAt: Date()
        )
    }
}

// MARK: - Выбор вопросов для экзамена

@MainActor
final class ExamQuestionSelectionTests: XCTestCase {

    func testExamQuestions_differBetweenExams() async throws {
        let useCase = makeUseCase(Self.questions(prefix: "m", count: 100, difficulty: .medium))
        var selectedSets = Set<Set<String>>()

        for _ in 0..<5 {
            let selected = try await useCase.loadExamQuestions(language: "ru", count: 10)
            XCTAssertEqual(selected.count, 10)
            XCTAssertEqual(Set(selected.map(\.id)).count, 10)
            selectedSets.insert(Set(selected.map(\.id)))
        }

        XCTAssertGreaterThan(selectedSets.count, 1, "Каждый экзамен состоит из одних и тех же вопросов")
    }

    func testExamQuestions_preferMediumAndHard() async throws {
        let useCase = makeUseCase(
            Self.questions(prefix: "e", count: 20, difficulty: .easy)
                + Self.questions(prefix: "h", count: 20, difficulty: .hard)
        )

        let selected = try await useCase.loadExamQuestions(language: "ru", count: 10)

        XCTAssertEqual(selected.count, 10)
        XCTAssertFalse(selected.contains { $0.difficulty == .easy })
    }

    func testExamQuestions_notEnoughHard_fillWithEasy() async throws {
        let useCase = makeUseCase(
            Self.questions(prefix: "h", count: 3, difficulty: .hard)
                + Self.questions(prefix: "e", count: 20, difficulty: .easy)
        )

        let selected = try await useCase.loadExamQuestions(language: "ru", count: 10)

        XCTAssertEqual(selected.count, 10)
        XCTAssertEqual(Set(selected.map(\.id)).count, 10)
        XCTAssertEqual(selected.filter { $0.difficulty == .hard }.count, 3)
    }

    // MARK: - Helpers

    private func makeUseCase(_ questions: [Question]) -> ExamUseCase {
        ExamUseCase(
            questionsRepository: StubQuestionsRepository(questions: questions),
            examStatisticsManager: NoopExamStatistics()
        )
    }

    private static func questions(prefix: String, count: Int, difficulty: Difficulty) -> [Question] {
        (0..<count).map { index in
            Question(
                id: "\(prefix)\(index)",
                text: "?",
                answers: [Answer(id: "a", text: "A"), Answer(id: "b", text: "B")],
                correctIndex: 0,
                category: "fiqh",
                difficulty: difficulty
            )
        }
    }
}

private struct StubQuestionsRepository: QuestionsRepositoryProtocol {
    let questions: [Question]

    func loadQuestions(language: String) async throws -> [Question] { questions }
}

private struct NoopExamStatistics: ExamStatisticsManaging {
    func updateStatistics(with result: ExamResult) {}
}
