//
//  StoredDataCompatibilityTests.swift
//  dinIslamTests
//
//  Сохранённые данные читаются без потерь, когда формат модели меняется:
//  отсутствующие поля получают значения по умолчанию, нечитаемые элементы массивов
//  пропускаются поодиночке, нечитаемые данные не стираются следующим сохранением.
//

import XCTest
@testable import dinIslam

@MainActor
final class StoredDataCompatibilityTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "StoredDataCompatibilityTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        super.tearDown()
    }

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))
    }

    // MARK: - Статистика

    func testUserStats_oldFormatWithoutNewFields_keepsStoredValues() throws {
        // Формат до появления тем, сложностей, исправленных ошибок и даты активности
        let stats = try decode(UserStats.self, """
        {
          "totalQuestionsStudied": 120,
          "correctAnswers": 90,
          "incorrectAnswers": 30,
          "wrongQuestionIds": ["q5", "q7"],
          "totalQuizzesCompleted": 12,
          "currentStreak": 2,
          "perfectScores": 3,
          "longestStreak": 4,
          "lastQuizPercentage": 80,
          "recentQuizResults": [{"percentage": 80, "date": 0, "questionsCount": 10}]
        }
        """)

        XCTAssertEqual(stats.totalQuestionsStudied, 120)
        XCTAssertEqual(stats.correctAnswers, 90)
        XCTAssertEqual(stats.wrongQuestionIds, ["q5", "q7"])
        XCTAssertEqual(stats.totalQuizzesCompleted, 12)
        XCTAssertEqual(stats.recentQuizResults.count, 1)
        XCTAssertEqual(stats.correctedMistakes, 0)
        XCTAssertTrue(stats.topicStats.isEmpty)
        XCTAssertTrue(stats.difficultyStats.isEmpty)
        XCTAssertNil(stats.lastActivityAt)
    }

    func testUserStats_currentFormat_roundTrips() throws {
        var stats = UserStats()
        stats.totalQuestionsStudied = 40
        stats.correctAnswers = 30
        stats.incorrectAnswers = 10
        stats.correctedMistakes = 2
        stats.wrongQuestionIds = ["q1"]
        stats.topicStats = ["prophets": TopicStat(correctAnswers: 3, totalAnswers: 4, streak: 1, longestStreak: 2)]
        stats.difficultyStats = ["hard": DifficultyStat(correctAnswers: 1, totalAnswers: 2, adaptiveScore: 50)]
        stats.recentQuizResults = [QuizResultRecord(percentage: 75, date: Date(timeIntervalSinceReferenceDate: 100), questionsCount: 4)]
        stats.lastActivityAt = Date(timeIntervalSinceReferenceDate: 100)

        let decoded = try roundTrip(stats)

        XCTAssertEqual(decoded.totalQuestionsStudied, 40)
        XCTAssertEqual(decoded.correctedMistakes, 2)
        XCTAssertEqual(decoded.wrongQuestionIds, ["q1"])
        XCTAssertEqual(decoded.topicStats["prophets"]?.longestStreak, 2)
        XCTAssertEqual(decoded.difficultyStats["hard"]?.adaptiveScore, 50)
        XCTAssertEqual(decoded.recentQuizResults, stats.recentQuizResults)
        XCTAssertEqual(decoded.lastActivityAt, stats.lastActivityAt)
    }

    func testUserStats_unreadableRecentResult_skipsOnlyThatResult() throws {
        let stats = try decode(UserStats.self, """
        {
          "totalQuestionsStudied": 5,
          "recentQuizResults": [
            {"percentage": 60, "date": 0, "questionsCount": 5},
            {"percentage": 70}
          ]
        }
        """)

        XCTAssertEqual(stats.totalQuestionsStudied, 5)
        XCTAssertEqual(stats.recentQuizResults.map(\.percentage), [60])
    }

    func testDailyProgress_missingFields_keepsStreak() throws {
        let progress = try decode(DailyProgress.self, #"{"currentStreak": 6, "lastActiveDay": 0}"#)

        XCTAssertEqual(progress.currentStreak, 6)
        XCTAssertEqual(progress.longestStreak, 0)
        XCTAssertNil(progress.lastDailyGoalDay)
    }

    func testReviewSchedule_itemWithoutDueDate_isDueNow() throws {
        let schedule = try decode(ReviewSchedule.self, #"{"items": {"q1": {"stage": 2}, "q2": {"stage": 1, "dueDate": 0}}}"#)

        XCTAssertEqual(schedule.count, 2)
        XCTAssertEqual(schedule.dueIds(at: Date()), ["q1", "q2"])
    }

    func testExamStatistics_missingFields_keepsStoredValues() throws {
        let statistics = try decode(ExamStatistics.self, #"{"totalExamsCompleted": 3, "examsPassed": 2, "bestScore": 95}"#)

        XCTAssertEqual(statistics.totalExamsCompleted, 3)
        XCTAssertEqual(statistics.examsPassed, 2)
        XCTAssertEqual(statistics.bestScore, 95)
        XCTAssertEqual(statistics.examsFailed, 0)
    }

    // MARK: - Настройки

    func testAppSettings_unknownLanguage_keepsOtherSettings() throws {
        let settings = try decode(AppSettings.self, #"{"language": "de", "soundEnabled": false, "hapticEnabled": false}"#)

        XCTAssertEqual(settings.language, .system)
        XCTAssertFalse(settings.soundEnabled)
        XCTAssertFalse(settings.hapticEnabled)
        XCTAssertTrue(settings.notificationsEnabled)
    }

    // MARK: - Профиль

    func testProfileProgress_unknownMasteryAndBrokenHistoryEntry_keepsTheRest() throws {
        let progress = try decode(ProfileProgress.self, """
        {
          "totalQuestionsAnswered": 50,
          "correctAnswers": 40,
          "masteryLevel": "grandmaster",
          "difficultyStats": [
            {"difficulty": "hard", "correctAnswers": 4, "totalAnswers": 5},
            {"difficulty": "legendary", "correctAnswers": 1, "totalAnswers": 1}
          ],
          "quizHistory": [
            {"id": "11111111-1111-1111-1111-111111111111", "date": 0, "percentage": 90},
            {"percentage": 10}
          ]
        }
        """)

        XCTAssertEqual(progress.totalQuestionsAnswered, 50)
        XCTAssertEqual(progress.correctAnswers, 40)
        XCTAssertEqual(progress.masteryLevel, .novice)
        XCTAssertEqual(progress.difficultyStats.map(\.difficulty), [.hard])
        XCTAssertEqual(progress.quizHistory.map(\.percentage), [90])
        XCTAssertTrue(progress.examHistory.isEmpty)
    }

    func testUserProfile_missingSectionsAndUnknownAuthMethod_keepsIdentityAndProgress() throws {
        let profile = try decode(UserProfile.self, """
        {
          "id": "user-1",
          "authMethod": "iCloudAccount",
          "customDisplayName": "Ахмед",
          "progress": {"totalQuestionsAnswered": 7}
        }
        """)

        XCTAssertEqual(profile.id, "user-1")
        XCTAssertEqual(profile.authMethod, .anonymous)
        XCTAssertEqual(profile.customDisplayName, "Ахмед")
        XCTAssertEqual(profile.progress.totalQuestionsAnswered, 7)
        XCTAssertEqual(profile.preferences, ProfilePreferences())
        XCTAssertEqual(profile.metadata.updatedAt, .distantPast)
    }

    func testUserProfile_currentFormat_roundTrips() throws {
        var progress = ProfileProgress(totalQuestionsAnswered: 20, correctAnswers: 15, examsTaken: 1)
        progress.quizHistory = [QuizHistoryEntry(date: Date(timeIntervalSinceReferenceDate: 10), percentage: 75, correctAnswers: 15, totalQuestions: 20, difficultyBreakdown: [:], topicBreakdown: [:])]
        progress.examHistory = [ExamHistoryEntry(date: Date(timeIntervalSinceReferenceDate: 20), percentage: 80, duration: 60, correctAnswers: 8, totalQuestions: 10, passed: true, configuration: ExamConfigurationSnapshot(configuration: .quick))]
        let profile = UserProfile(id: "user-2", authMethod: .signInWithApple, customDisplayName: "Имя", progress: progress)

        XCTAssertEqual(try roundTrip(profile), profile)
    }

    // MARK: - Нечитаемые данные

    func testDecodeStored_unreadableData_isBackedUpOnce() {
        let original = Data(#"{"totalQuestionsStudied": "много"}"#.utf8)
        userDefaults.set(original, forKey: "UserStats")

        // Значение не того типа подменяется значением по умолчанию — запись читается
        XCTAssertEqual(userDefaults.decodeStored(UserStats.self, forKey: "UserStats")?.totalQuestionsStudied, 0)
        XCTAssertNil(userDefaults.data(forKey: "UserStats.unreadable"))

        // Не JSON-объект — запись не читается и копируется
        let broken = Data("not json".utf8)
        userDefaults.set(broken, forKey: "UserStats")
        XCTAssertNil(userDefaults.decodeStored(UserStats.self, forKey: "UserStats"))
        XCTAssertEqual(userDefaults.data(forKey: "UserStats.unreadable"), broken)

        // Первая копия не перезаписывается следующей ошибкой
        userDefaults.set(Data("still broken".utf8), forKey: "UserStats")
        XCTAssertNil(userDefaults.decodeStored(UserStats.self, forKey: "UserStats"))
        XCTAssertEqual(userDefaults.data(forKey: "UserStats.unreadable"), broken)
    }

    func testStatsManager_unreadableStats_areKeptAsBackup() {
        let broken = Data("not json".utf8)
        userDefaults.set(broken, forKey: "UserStats")

        let manager = StatsManager(userDefaults: userDefaults)

        XCTAssertEqual(manager.stats.totalQuestionsStudied, 0)
        XCTAssertEqual(userDefaults.data(forKey: "UserStats.unreadable"), broken)
    }

    // MARK: - Достижения

    func testAchievements_storedState_isAppliedToCurrentDefinitions() throws {
        // Старая запись: устаревшие название и требование, плюс тип из более новой версии
        let stored = """
        [
          {"id": "first_quiz", "title": "Old", "description": "Old", "icon": "x", "colorName": "blue",
           "type": "first_quiz", "requirement": 999, "isUnlocked": true, "unlockedDate": 0},
          {"id": "future", "type": "future_type", "isUnlocked": true}
        ]
        """
        userDefaults.set(Data(stored.utf8), forKey: "UserAchievements")

        let manager = AchievementManager(userDefaults: userDefaults, notificationManager: NotificationManager())

        XCTAssertEqual(manager.achievements.count, AchievementType.allCases.count)
        let firstQuiz = try XCTUnwrap(manager.achievements.first { $0.id == "first_quiz" })
        XCTAssertTrue(firstQuiz.isUnlocked)
        XCTAssertEqual(firstQuiz.unlockedDate, Date(timeIntervalSinceReferenceDate: 0))
        XCTAssertEqual(firstQuiz.requirement, 1)
        XCTAssertNotEqual(firstQuiz.title, "Old")
        XCTAssertEqual(manager.achievements.filter(\.isUnlocked).count, 1)
    }
}
