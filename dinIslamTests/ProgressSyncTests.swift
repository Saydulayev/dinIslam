//
//  ProgressSyncTests.swift
//  dinIslamTests
//
//  Синхронизация полного снимка между устройствами: ответы складываются, ошибки и их
//  повторения переносятся, сброс и удаление доходят до других устройств, повторная
//  синхронизация ничего не меняет.
//

import CloudKit
import XCTest
@testable import dinIslam

// MARK: - Слияние

final class SyncMergerTests: XCTestCase {

    private let day = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func testDevices_higherSeqWins_ownContributionFromLocal() {
        let local: [String: DeviceContribution<AchievementCounters>] = [
            "me": DeviceContribution(seq: 5, counters: AchievementCounters(questionsStudied: 10)),
            "other": DeviceContribution(seq: 1, counters: AchievementCounters(questionsStudied: 1))
        ]
        let remote: [String: DeviceContribution<AchievementCounters>] = [
            "me": DeviceContribution(seq: 4, counters: AchievementCounters(questionsStudied: 8)),
            "other": DeviceContribution(seq: 2, counters: AchievementCounters(questionsStudied: 3)),
            "third": DeviceContribution(seq: 1, counters: AchievementCounters(questionsStudied: 7))
        ]

        let merged = SyncMerger.mergeDevices(local: local, remote: remote, deviceId: "me")

        XCTAssertEqual(merged["me"]?.counters.questionsStudied, 10)
        XCTAssertEqual(merged["other"]?.counters.questionsStudied, 3)
        XCTAssertEqual(merged["third"]?.counters.questionsStudied, 7)
        let total: AchievementCounters = merged.total()
        XCTAssertEqual(total.questionsStudied, 20)
    }

    func testReviewItems_threeWay_takesTheSideThatChanged() {
        let base = ["kept": item(1), "solvedLocally": item(2), "solvedRemotely": item(1), "changedRemotely": item(0)]
        let local = ["kept": item(1), "changedRemotely": item(0), "solvedRemotely": item(1), "newLocal": item(0)]
        let remote = ["kept": item(1), "solvedLocally": item(2), "changedRemotely": item(1), "newRemote": item(0)]

        let merged = SyncMerger.mergeReviewItems(local: local, remote: remote, base: base)

        XCTAssertEqual(Set(merged.keys), ["kept", "changedRemotely", "newLocal", "newRemote"])
        XCTAssertEqual(merged["changedRemotely"]?.stage, 1)
    }

    func testReviewItems_bothSidesChanged_keepsMistakeAtEarliestStage() {
        let base = ["q": item(1)]

        let solvedHereFailedThere = SyncMerger.mergeReviewItems(local: [:], remote: ["q": item(0)], base: base)
        XCTAssertEqual(solvedHereFailedThere["q"]?.stage, 0)

        let advancedOnBoth = SyncMerger.mergeReviewItems(local: ["q": item(2)], remote: ["q": item(3)], base: base)
        XCTAssertEqual(advancedOnBoth["q"]?.stage, 2)
    }

    func testNewerEpoch_replacesWholeSection() {
        var local = SyncSnapshot()
        local.stats.epoch = SyncEpoch(id: "reset", date: day)
        var remote = SyncSnapshot()
        remote.stats.devices = ["other": DeviceContribution(seq: 9, counters: StatsCounters(correctAnswers: 50))]
        remote.stats.reviewItems = ["q": item(0)]
        remote.questionPool.usedIds = ["q1"]

        let merged = SyncMerger.merge(local: local, remote: remote, reviewBase: [:], deviceId: "me")

        XCTAssertEqual(merged.stats.epoch.id, "reset")
        XCTAssertTrue(merged.stats.devices.isEmpty)
        XCTAssertTrue(merged.stats.reviewItems.isEmpty)
        // Другие группы не сбрасывались — сливаются как обычно
        XCTAssertEqual(merged.questionPool.usedIds, ["q1"])
    }

    func testTimestamped_laterWins_tieGoesToICloud() {
        let older = Timestamped<String?>(value: "Старое", updatedAt: day)
        let newer = Timestamped<String?>(value: "Новое", updatedAt: day.addingTimeInterval(1))
        let tie = Timestamped<String?>(value: "Другое", updatedAt: day)

        XCTAssertEqual(SyncMerger.latest(local: newer, remote: older).value, "Новое")
        XCTAssertEqual(SyncMerger.latest(local: older, remote: newer).value, "Новое")
        XCTAssertEqual(SyncMerger.latest(local: tie, remote: older).value, "Старое")
    }

    func testRecentResults_unionWithoutDuplicates_latestTen() {
        let shared = QuizResultRecord(percentage: 80, date: day, questionsCount: 20)
        let local = [shared] + (1...6).map { QuizResultRecord(percentage: 50, date: day.addingTimeInterval(Double($0)), questionsCount: 20) }
        let remote = [shared] + (1...6).map { QuizResultRecord(percentage: 60, date: day.addingTimeInterval(Double(-$0)), questionsCount: 20) }

        let merged = SyncMerger.mergeRecentResults(local, remote)

        XCTAssertEqual(merged.count, 10)
        XCTAssertEqual(merged.filter { $0 == shared }.count, 1)
        XCTAssertEqual(merged.first?.date, day.addingTimeInterval(6))
    }

    func testExamHistory_unionWithoutDuplicates_newestFirst() {
        func record(_ offset: Double, _ percentage: Double) -> ExamHistoryRecord {
            ExamHistoryRecord(
                date: day.addingTimeInterval(offset), totalQuestions: 20, correctAnswers: 15,
                incorrectAnswers: 5, skippedQuestions: 0, percentage: percentage, timeSpent: 300
            )
        }
        let shared = record(0, 75)

        let merged = SyncMerger.mergeExamHistory([shared, record(-10, 50)], [record(10, 90), shared])

        XCTAssertEqual(merged.map(\.percentage), [90, 75, 50])
    }

    func testDailyProgress_laterDayWins_recordIsMax() {
        var monday = DailyProgress()
        for offset in 0..<5 { monday.registerActivity(at: day.addingTimeInterval(Double(offset) * 86_400)) }
        var tuesday = DailyProgress()
        tuesday.registerActivity(at: day.addingTimeInterval(5 * 86_400))

        let merged = DailyProgress.merged(monday, tuesday)

        XCTAssertEqual(merged.streak(at: day.addingTimeInterval(5 * 86_400)), 1)
        XCTAssertEqual(merged.longestStreak, 5)
    }

    func testSnapshot_survivesEncoding_withFractionalDates() throws {
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000.123456)
        var snapshot = SyncSnapshot()
        snapshot.displayName = Timestamped(value: "Имя", updatedAt: date)
        snapshot.stats.lastQuiz = LastQuiz(date: date, percentage: 85)
        snapshot.stats.recentQuizResults = [QuizResultRecord(percentage: 85, date: date, questionsCount: 20)]
        snapshot.stats.reviewItems = ["q": ReviewItem(stage: 1, dueDate: date)]
        snapshot.achievements.unlocked = ["first_quiz": date]

        XCTAssertEqual(try SyncSnapshot.decoded(from: snapshot.encoded()), snapshot)
    }

    private func item(_ stage: Int) -> ReviewItem {
        ReviewItem(stage: stage, dueDate: day.addingTimeInterval(Double(stage) * 86_400))
    }
}

// MARK: - Устройства

@MainActor
final class ProgressSyncTests: XCTestCase {

    private var cloud: FakeCloud!
    private var devices: [TestDevice] = []

    override func setUp() {
        super.setUp()
        cloud = FakeCloud()
    }

    override func tearDown() {
        devices.forEach { $0.cleanUp() }
        devices = []
        cloud = nil
        super.tearDown()
    }

    private func makeDevice() -> TestDevice {
        let device = TestDevice(cloud: cloud)
        devices.append(device)
        return device
    }

    func testAnswersFromTwoDevices_addUp_andRepeatedSyncChangesNothing() async throws {
        let iPhone = makeDevice()
        let iPad = makeDevice()

        iPhone.answer([("1", true), ("2", true), ("3", false)])
        try await iPhone.sync()
        iPad.answer([("4", true), ("5", false)])
        try await iPad.sync()
        try await iPhone.sync()

        for device in [iPhone, iPad] {
            XCTAssertEqual(device.stats.stats.correctAnswers, 3)
            XCTAssertEqual(device.stats.stats.incorrectAnswers, 2)
            XCTAssertEqual(device.stats.stats.totalQuestionsStudied, 5)
            XCTAssertEqual(device.stats.stats.totalQuizzesCompleted, 2)
            XCTAssertEqual(device.stats.stats.topicStats["fiqh"]?.totalAnswers, 5)
            XCTAssertEqual(device.pool.getUsedIds(version: 1), ["1", "2", "3", "4", "5"])
        }

        let saves = cloud.saveCount
        try await iPhone.sync()
        try await iPad.sync()
        XCTAssertEqual(iPhone.stats.stats.correctAnswers, 3)
        XCTAssertEqual(iPad.stats.stats.correctAnswers, 3)
        XCTAssertEqual(cloud.saveCount, saves, "Без изменений снимок не сохраняется")
    }

    func testMistakes_andTheirRemoval_reachOtherDevice() async throws {
        let iPhone = makeDevice()
        let iPad = makeDevice()

        iPhone.answer([("q1", false), ("q2", true)])
        try await iPhone.sync()
        try await iPad.sync()
        XCTAssertEqual(iPad.stats.stats.wrongQuestionIds, ["q1"])
        XCTAssertTrue(iPad.stats.reviewSchedule.isTracked("q1"))

        iPad.stats.clearWrongQuestions()
        try await iPad.sync()
        try await iPhone.sync()
        XCTAssertTrue(iPhone.stats.stats.wrongQuestionIds.isEmpty)
        XCTAssertEqual(iPhone.stats.reviewSchedule.count, 0)
    }

    func testResetStatistics_onOneDevice_resetsOthers_butKeepsAchievements() async throws {
        let iPhone = makeDevice()
        let iPad = makeDevice()
        iPhone.answer([("1", true), ("2", false)])
        iPhone.achievements.applyUnlockedDates(["first_quiz": Date()])
        try await iPhone.sync()
        try await iPad.sync()
        XCTAssertEqual(iPad.stats.stats.correctAnswers, 1)

        iPad.resetStatistics()
        try await iPad.sync()
        try await iPhone.sync()

        for device in [iPhone, iPad] {
            XCTAssertEqual(device.stats.stats.correctAnswers, 0)
            XCTAssertTrue(device.stats.stats.wrongQuestionIds.isEmpty)
            XCTAssertTrue(device.pool.getUsedIds(version: 1).isEmpty)
            XCTAssertNotNil(device.achievements.unlockedDates["first_quiz"])
        }

        // После сброса ответы снова складываются
        iPhone.answer([("3", true)])
        try await iPhone.sync()
        try await iPad.sync()
        XCTAssertEqual(iPad.stats.stats.correctAnswers, 1)
    }

    func testDeleteAllData_removesDataInICloudAndOnOtherDevices() async throws {
        let iPhone = makeDevice()
        let iPad = makeDevice()
        iPhone.answer([("1", true), ("2", false)])
        iPhone.profile.name = Timestamped(value: "Ахмед", updatedAt: Date())
        iPhone.achievements.applyUnlockedDates(["first_quiz": Date()])
        try await iPhone.sync()
        try await iPad.sync()
        XCTAssertEqual(iPad.profile.name.value, "Ахмед")

        try await iPhone.service.deleteAllData(includeICloud: true)
        XCTAssertEqual(iPhone.stats.stats.correctAnswers, 0)
        XCTAssertEqual(cloud.snapshot?.stats.devices.isEmpty, true)
        XCTAssertNil(cloud.snapshot?.displayName.value)

        try await iPad.sync()
        XCTAssertEqual(iPad.stats.stats.correctAnswers, 0)
        XCTAssertTrue(iPad.stats.stats.wrongQuestionIds.isEmpty)
        XCTAssertTrue(iPad.pool.getUsedIds(version: 1).isEmpty)
        XCTAssertTrue(iPad.achievements.unlockedDates.isEmpty)
        XCTAssertNil(iPad.profile.name.value)
    }

    func testNameAndPhoto_latestChangeWins() async throws {
        let iPhone = makeDevice()
        let iPad = makeDevice()
        let photo = Data([1, 2, 3])
        iPhone.profile.setAvatar(photo, at: Date(timeIntervalSinceNow: -10))
        iPhone.profile.name = Timestamped(value: "Старое", updatedAt: Date(timeIntervalSinceNow: -10))
        try await iPhone.sync()
        try await iPad.sync()
        XCTAssertEqual(iPad.profile.avatarData, photo)

        iPad.profile.name = Timestamped(value: "Новое", updatedAt: Date())
        iPad.profile.setAvatar(nil, at: Date())
        try await iPad.sync()
        try await iPhone.sync()

        XCTAssertEqual(iPhone.profile.name.value, "Новое")
        XCTAssertNil(iPhone.profile.avatarData)
        XCTAssertNil(cloud.avatarData)
    }

    func testConcurrentSave_isMergedAgain_withoutLosingAnswers() async throws {
        let iPhone = makeDevice()
        let iPad = makeDevice()
        iPhone.answer([("1", true)])
        iPad.answer([("2", true)])
        // Пока iPhone сливает снимок, iPad успевает сохранить свой
        cloud.beforeNextSave = { try await iPad.sync() }

        try await iPhone.sync()
        try await iPad.sync()

        XCTAssertEqual(iPhone.stats.stats.correctAnswers, 2)
        XCTAssertEqual(iPad.stats.stats.correctAnswers, 2)
    }

    func testFirstSync_mergesLocalData_evenIfDeviceWasResetBefore() async throws {
        let iPhone = makeDevice()
        iPhone.answer([("1", true)])
        try await iPhone.sync()

        let iPad = makeDevice()
        iPad.resetStatistics()
        iPad.answer([("2", true)])
        try await iPad.sync()
        try await iPhone.sync()

        XCTAssertEqual(iPad.stats.stats.correctAnswers, 2)
        XCTAssertEqual(iPhone.stats.stats.correctAnswers, 2)
    }

    func testAccountChange_replacesLocalDataWithNewAccount() async throws {
        let iPhone = makeDevice()
        iPhone.answer([("1", true)])
        try await iPhone.sync()

        cloud.switchAccount()
        try await iPhone.sync()

        XCTAssertEqual(iPhone.stats.stats.correctAnswers, 0)
        XCTAssertEqual(cloud.snapshot?.stats.devices.values.first?.counters.correctAnswers ?? 0, 0)
    }
}

// MARK: - Test Doubles

@MainActor
private final class TestDevice {
    let suiteName = "ProgressSyncTests.\(UUID().uuidString)"
    let defaults: UserDefaults
    let stats: StatsManager
    let exams: ExamStatisticsManager
    let pool: DefaultQuestionPoolProgressManager
    let achievements: AchievementManager
    let profile = FakeProfile()
    let service: ProgressSyncService

    init(cloud: FakeCloud) {
        defaults = UserDefaults(suiteName: suiteName)!
        stats = StatsManager(userDefaults: defaults)
        exams = ExamStatisticsManager(userDefaults: defaults)
        pool = DefaultQuestionPoolProgressManager(userDefaults: defaults)
        achievements = AchievementManager(userDefaults: defaults, notificationManager: NotificationManager())
        service = ProgressSyncService(
            cloudService: cloud,
            stateStore: LocalSyncStateStore(userDefaults: defaults),
            statsManager: stats,
            examStatisticsManager: exams,
            questionPoolProgressManager: pool,
            achievementManager: achievements
        )
        service.profileProvider = profile
    }

    func answer(_ outcomes: [(String, Bool)]) {
        let items = outcomes.map { QuizQuestionOutcome(questionId: $0.0, category: "fiqh", difficulty: .medium, isCorrect: $0.1) }
        let correct = items.filter(\.isCorrect).count
        stats.recordQuizSession(QuizSessionSummary(
            correctAnswers: correct,
            totalQuestions: items.count,
            percentage: Double(correct) / Double(items.count) * 100,
            duration: 60,
            completedAt: Date(),
            outcomes: items
        ))
        pool.markUsed(items.map(\.questionId), version: 1)
    }

    /// Как в ProfileManager.resetProfileData: сброс хранилищ и новое поколение сброшенных групп
    func resetStatistics() {
        stats.resetStats()
        exams.resetStatistics()
        pool.reset(version: 1)
        service.startNewEpoch(for: [.stats, .achievementProgress, .questionPool])
    }

    func sync() async throws {
        try await service.sync()
    }

    func cleanUp() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

@MainActor
private final class FakeProfile: SyncProfileProviding {
    var name = Timestamped<String?>(value: nil, updatedAt: .distantPast)
    var avatarData: Data?
    var avatarUpdatedAt = Date.distantPast
    private let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")

    func setAvatar(_ data: Data?, at date: Date) {
        avatarData = data
        avatarUpdatedAt = date
    }

    var syncDisplayName: Timestamped<String?> { name }

    var syncAvatar: Timestamped<String> {
        Timestamped(value: avatarData.map { AvatarImageProcessor.fingerprint(of: $0) } ?? "", updatedAt: avatarUpdatedAt)
    }

    var syncAvatarFileURL: URL? {
        guard let avatarData else { return nil }
        try? avatarData.write(to: fileURL)
        return fileURL
    }

    func applySyncedDisplayName(_ displayName: Timestamped<String?>) {
        name = displayName
    }

    func applySyncedAvatar(_ avatar: Timestamped<String>, data: Data?) {
        if avatar.value.isEmpty {
            avatarData = nil
        } else if let data {
            avatarData = data
        }
        avatarUpdatedAt = avatar.updatedAt
    }

    func clearProfileForSync() {
        name = Timestamped(value: nil, updatedAt: .distantPast)
        avatarData = nil
        avatarUpdatedAt = .distantPast
    }
}

/// iCloud в памяти: запись с номером изменения, сохранение устаревшей записи — `serverRecordChanged`
private final class FakeCloud: ProfileCloudStoring {
    private(set) var snapshot: SyncSnapshot?
    private(set) var avatarData: Data?
    private(set) var saveCount = 0
    private var changeTag = 0
    private var account = "account-1"
    var beforeNextSave: (() async throws -> Void)?

    func switchAccount() {
        account = "account-2"
        snapshot = nil
        avatarData = nil
        changeTag += 1
    }

    func accountId() async throws -> String {
        account
    }

    func fetchProfileRecord() async throws -> RemoteProfileRecord? {
        guard let snapshot else { return nil }
        let record = CKRecord(recordType: "UserProfile", recordID: CKRecord.ID(recordName: "profile"))
        record["changeTag"] = changeTag as CKRecordValue
        return RemoteProfileRecord(record: record, snapshot: snapshot)
    }

    func fetchAvatarData() async throws -> Data? {
        avatarData
    }

    func save(_ snapshot: SyncSnapshot, to existingRecord: CKRecord?, avatar: AvatarUpload) async throws {
        if let beforeNextSave {
            self.beforeNextSave = nil
            try await beforeNextSave()
        }
        let expectedTag = existingRecord?["changeTag"] as? Int
        guard expectedTag == (self.snapshot == nil ? nil : changeTag) else {
            throw CKError(.serverRecordChanged)
        }
        self.snapshot = snapshot
        switch avatar {
        case .keep: break
        case .upload(let url): avatarData = try Data(contentsOf: url)
        case .remove: avatarData = nil
        }
        changeTag += 1
        saveCount += 1
    }
}
