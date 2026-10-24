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

    /// Пропуск — неверный ответ, а не автоматический провал
    func testIsPassed_percentage70WithSkipped_returnsTrue() {
        let result = makeResult(percentage: 70.0, skippedQuestions: 1)
        XCTAssertTrue(result.isPassed)
    }

    func testIsPassed_highPercentageWithSkipped_returnsTrue() {
        let result = makeResult(percentage: 95.0, skippedQuestions: 1)
        XCTAssertTrue(result.isPassed)
    }

    func testIsPassed_skipsDropPercentageBelow70_returnsFalse() {
        let result = makeResult(percentage: 65.0, skippedQuestions: 7)
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

    func testStatistics_historyNewestFirst_limited() {
        var statistics = ExamStatistics()
        let start = Date(timeIntervalSinceReferenceDate: 0)
        for index in 0..<(ExamStatistics.historyLimit + 5) {
            statistics.updateStatistics(with: makeResult(
                percentage: 80,
                completedAt: start.addingTimeInterval(Double(index))
            ))
        }

        XCTAssertEqual(statistics.history.count, ExamStatistics.historyLimit)
        XCTAssertEqual(statistics.history.first?.date, start.addingTimeInterval(Double(ExamStatistics.historyLimit + 4)))
        XCTAssertEqual(statistics.totalExamsCompleted, ExamStatistics.historyLimit + 5)
    }

    func testHistoryRecord_keepsResult() {
        let record = ExamHistoryRecord(result: makeResult(percentage: 85, skippedQuestions: 2))

        XCTAssertEqual(record.totalQuestions, 20)
        XCTAssertEqual(record.correctAnswers, 17)
        XCTAssertEqual(record.skippedQuestions, 2)
        XCTAssertTrue(record.isPassed)
        XCTAssertEqual(record.grade, .good)
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
        totalQuestions: Int = 20,
        completedAt: Date = Date()
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
            completedAt: completedAt
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

// MARK: - Пул вопросов викторины

@MainActor
final class QuizQuestionPoolTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var pool: DefaultQuestionPoolProgressManager!

    override func setUp() {
        super.setUp()
        suiteName = "QuizQuestionPoolTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        pool = DefaultQuestionPoolProgressManager(userDefaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testLearningMode_onlyNewQuestions_withoutRepeats() async throws {
        let questions = Self.questions(count: 50)
        pool.markUsed((0..<10).map { "q\($0)" }, version: 1)

        let selected = try await makeUseCase(questions).startQuiz(language: "ru", sessionSize: 20)

        XCTAssertEqual(selected.count, 20)
        XCTAssertEqual(Set(selected.map(\.id)).count, 20)
        XCTAssertTrue(Set(selected.map(\.id)).isDisjoint(with: pool.getUsedIds(version: 1)))
    }

    /// Новых вопросов меньше размера сессии — сессия короче, уже пройденные не добавляются
    func testLearningMode_fewNewQuestionsLeft_returnsOnlyThem() async throws {
        let questions = Self.questions(count: 25)
        pool.markUsed((0..<20).map { "q\($0)" }, version: 1)

        let selected = try await makeUseCase(questions).startQuiz(language: "ru", sessionSize: 20)

        XCTAssertEqual(Set(selected.map(\.id)), Set((20..<25).map { "q\($0)" }))
    }

    func testBankCompleted_withoutReviewMode_returnsNothing() async throws {
        let questions = Self.questions(count: 10)
        pool.markUsed(questions.map(\.id), version: 1)
        let useCase = makeUseCase(questions)

        let selected = try await useCase.startQuiz(language: "ru", sessionSize: 20)
        let completion = try await useCase.isBankCompleted(language: "ru")

        XCTAssertTrue(selected.isEmpty)
        XCTAssertTrue(completion.isCompleted)
        XCTAssertEqual(completion.totalQuestions, 10)
        XCTAssertEqual(completion.studiedCount, 10)
    }

    /// Режим повторения пройденного банка: вопросы повторяются, но не дублируются внутри сессии
    func testReviewMode_completedBank_repeatsQuestions() async throws {
        let questions = Self.questions(count: 30)
        pool.markUsed(questions.map(\.id), version: 1)
        pool.setReviewMode(true, version: 1)

        let selected = try await makeUseCase(questions).startQuiz(language: "ru", sessionSize: 20)

        XCTAssertEqual(selected.count, 20)
        XCTAssertEqual(Set(selected.map(\.id)).count, 20)
    }

    /// Пройденные id удалённых из банка вопросов не делают банк пройденным
    func testRemovedQuestionIds_doNotCompleteBank() async throws {
        let questions = Self.questions(count: 5)
        pool.markUsed(["q0", "q1", "old1", "old2", "old3"], version: 1)
        let useCase = makeUseCase(questions)

        let completion = try await useCase.isBankCompleted(language: "ru")
        let selected = try await useCase.startQuiz(language: "ru", sessionSize: 20)

        XCTAssertFalse(completion.isCompleted)
        XCTAssertEqual(completion.studiedCount, 2)
        XCTAssertEqual(Set(selected.map(\.id)), ["q2", "q3", "q4"])
    }

    func testMarkQuestionsUsed_excludesThemFromNextSession() async throws {
        let questions = Self.questions(count: 30)
        let useCase = makeUseCase(questions)

        let first = try await useCase.startQuiz(language: "ru", sessionSize: 20)
        useCase.markQuestionsUsed(first.map(\.id))
        let second = try await useCase.startQuiz(language: "ru", sessionSize: 20)

        XCTAssertEqual(second.count, 10)
        XCTAssertTrue(Set(first.map(\.id)).isDisjoint(with: Set(second.map(\.id))))
    }

    /// Слабые темы (от 5 ответов, точность ниже 70%) занимают не меньше половины сессии, если вопросов хватает
    func testWeakTopic_getsAtLeastHalfOfSession() async throws {
        let questions = Self.questions(count: 30, category: "fiqh") + Self.questions(count: 30, category: "aqida", prefix: "a")
        var weak = TopicStat()
        weak.totalAnswers = 10
        weak.correctAnswers = 3

        let selected = try await makeUseCase(questions, topicStats: ["fiqh": weak]).startQuiz(language: "ru", sessionSize: 20)

        XCTAssertEqual(selected.count, 20)
        XCTAssertGreaterThanOrEqual(selected.filter { $0.category == "fiqh" }.count, 10)
    }

    func testDailyQuiz_takesNewQuestions() async throws {
        let questions = Self.questions(count: 30)
        pool.markUsed((0..<25).map { "q\($0)" }, version: 1)

        let selected = try await makeUseCase(questions).startDailyQuiz(language: "ru")

        XCTAssertEqual(Set(selected.map(\.id)), Set((25..<30).map { "q\($0)" }))
    }

    /// Ежедневная практика доступна и после прохождения банка: добирается пройденными
    func testDailyQuiz_completedBank_stillHasFullSession() async throws {
        let questions = Self.questions(count: 30)
        pool.markUsed(questions.map(\.id), version: 1)

        let selected = try await makeUseCase(questions).startDailyQuiz(language: "ru")

        XCTAssertEqual(selected.count, DailyProgress.dailyGoalQuestions)
        XCTAssertEqual(Set(selected.map(\.id)).count, DailyProgress.dailyGoalQuestions)
    }

    func testDailyQuiz_fewNewQuestions_filledWithStudied_withoutDuplicates() async throws {
        let questions = Self.questions(count: 30)
        pool.markUsed((0..<28).map { "q\($0)" }, version: 1)

        let selected = try await makeUseCase(questions).startDailyQuiz(language: "ru")
        let ids = Set(selected.map(\.id))

        XCTAssertEqual(selected.count, DailyProgress.dailyGoalQuestions)
        XCTAssertEqual(ids.count, DailyProgress.dailyGoalQuestions)
        XCTAssertTrue(ids.isSuperset(of: ["q28", "q29"]))
    }

    // MARK: - Helpers

    private func makeUseCase(_ questions: [Question], topicStats: [String: TopicStat] = [:]) -> QuizUseCase {
        QuizUseCase(
            questionsRepository: StubQuestionsRepository(questions: questions),
            topicStatsProvider: StubTopicStats(topicStats: topicStats),
            questionSelectionStrategy: AdaptiveQuestionSelectionStrategy(adaptiveEngine: AdaptiveLearningEngine()),
            questionPoolProgressManager: pool
        )
    }

    private static func questions(count: Int, category: String = "fiqh", prefix: String = "q") -> [Question] {
        (0..<count).map { index in
            Question(
                id: "\(prefix)\(index)",
                text: "?",
                answers: [Answer(id: "a", text: "A"), Answer(id: "b", text: "B")],
                correctIndex: 0,
                category: category,
                difficulty: .medium
            )
        }
    }
}

private struct StubTopicStats: TopicStatsProviding {
    let topicStats: [String: TopicStat]
}

private struct StubQuestionsRepository: QuestionsRepositoryProtocol {
    let questions: [Question]

    func loadQuestions(language: String) async throws -> [Question] { questions }
}

private struct NoopExamStatistics: ExamStatisticsManaging {
    func updateStatistics(with result: ExamResult) {}
}
