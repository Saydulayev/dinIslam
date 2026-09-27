//
//  LearningLoopTests.swift
//  dinIslamTests
//
//  Интервальное повторение ошибок, серия дней, новые поля вопросов (тема, сложность, пояснение).
//  Тесты помечены @MainActor: в приложении типы по умолчанию привязаны к главному потоку.
//

import XCTest
@testable import dinIslam

@MainActor
final class ReviewScheduleTests: XCTestCase {

    private var calendar: Calendar!
    private var day0: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        day0 = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 15))!
    }

    private func day(_ offset: Int, hour: Int = 10) -> Date {
        let start = calendar.startOfDay(for: day0)
        return calendar.date(byAdding: DateComponents(day: offset, hour: hour), to: start)!
    }

    func testMistake_isDueNextMorning() {
        var schedule = ReviewSchedule()
        schedule.registerMistake("q1", at: day0, calendar: calendar)

        XCTAssertTrue(schedule.dueIds(at: day(0, hour: 23)).isEmpty)
        XCTAssertEqual(schedule.dueIds(at: day(1, hour: 0)), ["q1"])
    }

    func testCorrectAnswersOnTime_graduateAfterAllIntervals() {
        var schedule = ReviewSchedule()
        schedule.registerMistake("q1", at: day0, calendar: calendar)

        XCTAssertEqual(schedule.recordAnswer("q1", isCorrect: true, at: day(1), calendar: calendar), .advanced(nextDue: day(4, hour: 0)))
        XCTAssertEqual(schedule.recordAnswer("q1", isCorrect: true, at: day(4), calendar: calendar), .advanced(nextDue: day(11, hour: 0)))
        XCTAssertEqual(schedule.recordAnswer("q1", isCorrect: true, at: day(11), calendar: calendar), .advanced(nextDue: day(25, hour: 0)))
        XCTAssertEqual(schedule.recordAnswer("q1", isCorrect: true, at: day(25), calendar: calendar), .graduated)
        XCTAssertFalse(schedule.isTracked("q1"))
    }

    func testCorrectAnswerBeforeDue_doesNotAdvance() {
        var schedule = ReviewSchedule()
        schedule.registerMistake("q1", at: day0, calendar: calendar)

        XCTAssertEqual(schedule.recordAnswer("q1", isCorrect: true, at: day(0, hour: 20), calendar: calendar), .notDue)
        XCTAssertEqual(schedule.dueIds(at: day(1)), ["q1"])
    }

    func testWrongAnswer_resetsToTomorrow() {
        var schedule = ReviewSchedule()
        schedule.registerMistake("q1", at: day0, calendar: calendar)
        schedule.recordAnswer("q1", isCorrect: true, at: day(1), calendar: calendar)

        XCTAssertEqual(schedule.recordAnswer("q1", isCorrect: false, at: day(4), calendar: calendar), .reset(nextDue: day(5, hour: 0)))
        // Снова нужно пройти все этапы
        XCTAssertEqual(schedule.recordAnswer("q1", isCorrect: true, at: day(5), calendar: calendar), .advanced(nextDue: day(8, hour: 0)))
    }

    func testUntrackedQuestion_isIgnored() {
        var schedule = ReviewSchedule()
        XCTAssertEqual(schedule.recordAnswer("q1", isCorrect: true, at: day0, calendar: calendar), .notTracked)
        XCTAssertEqual(schedule.count, 0)
    }

    func testSync_addsLegacyMistakesAsDueNow_andDropsStaleItems() {
        var schedule = ReviewSchedule()
        schedule.registerMistake("stale", at: day0, calendar: calendar)

        schedule.sync(with: ["old1", "old2"], now: day0)

        XCTAssertEqual(schedule.dueIds(at: day0), ["old1", "old2"])
        XCTAssertFalse(schedule.isTracked("stale"))
    }

    func testNextDueDate_isEarliestFutureDate() {
        var schedule = ReviewSchedule()
        schedule.registerMistake("q1", at: day0, calendar: calendar)
        schedule.registerMistake("q2", at: day(2), calendar: calendar)

        XCTAssertEqual(schedule.nextDueDate(after: day0), day(1, hour: 0))
    }
}

@MainActor
final class DailyProgressTests: XCTestCase {

    private var calendar: Calendar!
    private var start: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 9))!
    }

    private func day(_ offset: Int, hour: Int = 9) -> Date {
        calendar.date(byAdding: DateComponents(day: offset, hour: hour - 9), to: start)!
    }

    func testConsecutiveDays_growStreak_sameDayCountsOnce() {
        var progress = DailyProgress()
        progress.registerActivity(at: day(0), calendar: calendar)
        progress.registerActivity(at: day(0, hour: 22), calendar: calendar)
        progress.registerActivity(at: day(1), calendar: calendar)
        progress.registerActivity(at: day(2, hour: 23), calendar: calendar)

        XCTAssertEqual(progress.streak(at: day(2), calendar: calendar), 3)
        XCTAssertEqual(progress.longestStreak, 3)
    }

    func testStreak_survivesUntilEndOfNextDay_thenBreaks() {
        var progress = DailyProgress()
        progress.registerActivity(at: day(0), calendar: calendar)
        progress.registerActivity(at: day(1), calendar: calendar)

        XCTAssertEqual(progress.streak(at: day(2, hour: 23), calendar: calendar), 2, "Вчера занимались — серия ещё жива")
        XCTAssertEqual(progress.streak(at: day(3), calendar: calendar), 0, "Пропущен целый день — серия прервана")
    }

    func testGap_restartsStreak_keepsLongest() {
        var progress = DailyProgress()
        progress.registerActivity(at: day(0), calendar: calendar)
        progress.registerActivity(at: day(1), calendar: calendar)
        progress.registerActivity(at: day(5), calendar: calendar)

        XCTAssertEqual(progress.streak(at: day(5), calendar: calendar), 1)
        XCTAssertEqual(progress.longestStreak, 2)
    }

    func testDailyGoal_isPerDay_andCountsAsActivity() {
        var progress = DailyProgress()
        progress.registerDailyGoal(at: day(0), calendar: calendar)

        XCTAssertTrue(progress.isDailyGoalCompleted(on: day(0, hour: 23), calendar: calendar))
        XCTAssertFalse(progress.isDailyGoalCompleted(on: day(1), calendar: calendar))
        XCTAssertTrue(progress.isActive(on: day(0), calendar: calendar))
        XCTAssertEqual(progress.streak(at: day(0), calendar: calendar), 1)
    }
}

@MainActor
final class StatsManagerReviewTests: XCTestCase {

    private var defaults: UserDefaults!
    private var suiteName: String!
    private var now: Date!

    override func setUp() {
        super.setUp()
        suiteName = "StatsManagerReviewTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        now = Date()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private func makeManager() -> StatsManager {
        StatsManager(userDefaults: defaults, now: { [unowned self] in self.now })
    }

    private func summary(_ outcomes: [(String, Bool)]) -> QuizSessionSummary {
        let items = outcomes.map {
            QuizQuestionOutcome(questionId: $0.0, category: "fiqh", difficulty: .medium, isCorrect: $0.1)
        }
        let correct = items.filter(\.isCorrect).count
        return QuizSessionSummary(
            correctAnswers: correct,
            totalQuestions: items.count,
            percentage: Double(correct) / Double(items.count) * 100,
            duration: 60,
            completedAt: now,
            outcomes: items
        )
    }

    func testQuizMistakes_areScheduledForTomorrow_andStreakStarts() {
        let manager = makeManager()
        manager.recordQuizSession(summary([("q1", false), ("q2", true)]))

        XCTAssertEqual(manager.stats.wrongQuestionIds, ["q1"])
        XCTAssertEqual(manager.dueReviewCount, 0)
        XCTAssertEqual(manager.dayStreak, 1)

        now = now.addingTimeInterval(2 * 86_400)
        XCTAssertEqual(manager.dueReviewCount, 1)
    }

    func testReviewCorrectBeforeDue_keepsMistake() {
        let manager = makeManager()
        manager.recordQuizSession(summary([("q1", false)]))

        let result = manager.recordReviewAnswers(["q1": true])

        XCTAssertEqual(result.notDue, 1)
        XCTAssertEqual(manager.stats.wrongQuestionIds, ["q1"], "Вопрос выучен только после интервальных повторений")
    }

    func testReviewThroughAllStages_removesMistake_andCountsCorrection() {
        let manager = makeManager()
        manager.recordQuizSession(summary([("q1", false)]))

        for days in [1, 3, 7, 14] {
            now = now.addingTimeInterval(Double(days + 1) * 86_400)
            _ = manager.recordReviewAnswers(["q1": true])
        }

        XCTAssertTrue(manager.stats.wrongQuestionIds.isEmpty)
        XCTAssertEqual(manager.stats.correctedMistakes, 1)
        XCTAssertEqual(manager.reviewSchedule.count, 0)
    }

    func testState_persistsBetweenLaunches() {
        let manager = makeManager()
        manager.recordQuizSession(summary([("q1", false)]))
        manager.registerDailyGoal()

        let relaunched = makeManager()
        XCTAssertTrue(relaunched.reviewSchedule.isTracked("q1"))
        XCTAssertTrue(relaunched.isDailyGoalCompletedToday)
        XCTAssertEqual(relaunched.dayStreak, 1)
    }

    func testLegacyMistakes_becomeDueImmediately() throws {
        var legacy = UserStats()
        legacy.wrongQuestionIds = ["old"]
        defaults.set(try JSONEncoder().encode(legacy), forKey: "UserStats")

        let manager = makeManager()

        XCTAssertEqual(manager.dueReviewCount, 1)
    }

    func testReset_clearsScheduleAndStreak() {
        let manager = makeManager()
        manager.recordQuizSession(summary([("q1", false)]))

        manager.resetStats()

        XCTAssertEqual(manager.reviewSchedule.count, 0)
        XCTAssertEqual(manager.dayStreak, 0)
    }
}

@MainActor
final class QuestionFormatTests: XCTestCase {

    func testShortKeys_categoryDifficultyExplanation() throws {
        let json = """
        [{"id": "q1", "q": "Вопрос?", "a": ["А", "Б"], "c": 1,
          "cat": "prophets", "d": "hard", "exp": "  Потому что так.  "}]
        """
        let question = try XCTUnwrap(QuestionsFile.decode(Data(json.utf8)).first)

        XCTAssertEqual(question.category, "prophets")
        XCTAssertEqual(question.difficulty, .hard)
        XCTAssertEqual(question.explanation, "Потому что так.")
        XCTAssertTrue(question.hasExplanation)
    }

    func testOldFormat_withoutNewFields_stillLoads() throws {
        let json = """
        [{"id": "q1", "q": "Вопрос?", "a": ["А", "Б"], "c": 0}]
        """
        let question = try XCTUnwrap(QuestionsFile.decode(Data(json.utf8)).first)

        XCTAssertEqual(question.category, QuestionCategory.generalId)
        XCTAssertEqual(question.difficulty, .medium)
        XCTAssertNil(question.explanation)
        XCTAssertFalse(question.hasExplanation)
    }

    func testEmptyExplanation_isTreatedAsMissing() throws {
        let json = """
        [{"id": "q1", "q": "Вопрос?", "a": ["А", "Б"], "c": 0, "exp": "   "}]
        """
        let question = try XCTUnwrap(QuestionsFile.decode(Data(json.utf8)).first)
        XCTAssertNil(question.explanation)
    }

    func testShuffle_keepsExplanationAndCategory() {
        let question = Question(
            id: "q1",
            text: "?",
            answers: [Answer(id: "a1", text: "A"), Answer(id: "a2", text: "B"), Answer(id: "a3", text: "C")],
            correctIndex: 2,
            category: "fiqh",
            difficulty: .easy,
            explanation: "Пояснение"
        )

        let shuffled = question.withAnswers(question.answers.reversed(), correctIndex: 0)

        XCTAssertEqual(shuffled.explanation, "Пояснение")
        XCTAssertEqual(shuffled.category, "fiqh")
        XCTAssertEqual(shuffled.answers[shuffled.correctIndex].id, "a3")
    }

    func testTopicResults_groupAndSortByVolume() {
        let outcomes = [
            QuizQuestionOutcome(questionId: "1", category: "fiqh", difficulty: .easy, isCorrect: true),
            QuizQuestionOutcome(questionId: "2", category: "seerah", difficulty: .easy, isCorrect: false),
            QuizQuestionOutcome(questionId: "3", category: "seerah", difficulty: .easy, isCorrect: true)
        ]

        let results = SessionReport.topicResults(for: outcomes)

        XCTAssertEqual(results.map(\.categoryId), ["seerah", "fiqh"])
        XCTAssertEqual(results.first?.correct, 1)
        XCTAssertEqual(results.first?.total, 2)
    }

    func testBundledQuestions_useKnownCategoriesAndDifficulties() throws {
        for language in [AppLanguage.russian, .english] {
            let questions = try QuestionsFile.loadBundled(for: language)
            XCTAssertFalse(questions.isEmpty)
            let known = Set(QuestionCategory.allCases.map(\.rawValue)).union([QuestionCategory.generalId])
            for question in questions {
                XCTAssertTrue(known.contains(question.category), "\(question.id): неизвестная тема \(question.category)")
            }
        }
    }
}
