//
//  ProgressSyncService.swift
//  dinIslam
//
//  Синхронизация полного снимка: снимок устройства сливается со снимком из iCloud,
//  результат применяется к хранилищам на устройстве и сохраняется в iCloud.
//

import Foundation

/// Имя и фото — у ProfileManager; остальные данные — в хранилищах
@MainActor
protocol SyncProfileProviding: AnyObject {
    var syncDisplayName: Timestamped<String?> { get }
    /// Отпечаток локального фото (`""` — фото нет) и время его выбора
    var syncAvatar: Timestamped<String> { get }
    var syncAvatarFileURL: URL? { get }
    func applySyncedDisplayName(_ displayName: Timestamped<String?>)
    /// Пустой отпечаток — фото удалено; `data` — новое фото; `nil` при непустом отпечатке — фото то же,
    /// обновляется только время выбора
    func applySyncedAvatar(_ avatar: Timestamped<String>, data: Data?)
    /// Удаление данных или смена аккаунта iCloud: имя и фото устройства стираются
    func clearProfileForSync()
}

@MainActor
final class ProgressSyncService {
    private let cloudService: ProfileCloudStoring
    private let stateStore: LocalSyncStateStore
    private let statsManager: StatsManager
    private let examStatisticsManager: ExamStatisticsManager
    private let questionPoolProgressManager: QuestionPoolProgressManaging
    private let achievementManager: AchievementManager
    private let questionPoolVersion = 1
    private let maxSaveAttempts = 3

    weak var profileProvider: SyncProfileProviding?

    init(
        cloudService: ProfileCloudStoring,
        stateStore: LocalSyncStateStore,
        statsManager: StatsManager,
        examStatisticsManager: ExamStatisticsManager,
        questionPoolProgressManager: QuestionPoolProgressManaging,
        achievementManager: AchievementManager
    ) {
        self.cloudService = cloudService
        self.stateStore = stateStore
        self.statsManager = statsManager
        self.examStatisticsManager = examStatisticsManager
        self.questionPoolProgressManager = questionPoolProgressManager
        self.achievementManager = achievementManager
    }

    /// Сброс на устройстве: для этих групп начинается новое поколение
    func startNewEpoch(for sections: [SyncSection]) {
        stateStore.startNewEpoch(for: sections)
    }

    // MARK: - Sync
    /// Сливает данные устройства и iCloud, применяет результат на устройстве и сохраняет в iCloud
    func sync() async throws {
        let accountId = try await cloudService.accountId()
        if let knownAccountId = stateStore.state.accountId, knownAccountId != accountId {
            // На устройстве сменили Apple ID: данные прежнего аккаунта остаются в его iCloud
            AppLogger.info("iCloud account changed, replacing local data", category: AppLogger.data)
            wipeLocalData(epochs: SyncSnapshot())
        }

        for attempt in 1...maxSaveAttempts {
            let remote = try await cloudService.fetchProfileRecord()
            let remoteSnapshot = remote?.snapshot

            // Первая синхронизация с этим аккаунтом объединяет данные устройства с данными iCloud,
            // даже если на устройстве до входа в iCloud что-то сбрасывали
            if stateStore.state.accountId == nil, let remoteSnapshot {
                stateStore.update { state in
                    for section in SyncSection.allCases {
                        state.setEpoch(remoteSnapshot.epoch(of: section), for: section)
                    }
                }
            }

            let local = makeLocalSnapshot(remote: remoteSnapshot)
            let merged = SyncMerger.merge(
                local: local,
                remote: remoteSnapshot,
                reviewBase: stateStore.state.reviewBase,
                deviceId: stateStore.state.deviceId
            )

            let localAvatarHash = local.avatar.value
            apply(merged)
            await applyProfile(merged, localAvatarHash: localAvatarHash)

            if merged != remoteSnapshot {
                do {
                    try await cloudService.save(
                        merged,
                        to: remote?.record,
                        avatar: avatarUpload(merged: merged, remote: remoteSnapshot, localAvatarHash: localAvatarHash)
                    )
                } catch where error.isServerRecordChanged && attempt < maxSaveAttempts {
                    // Запись изменило другое устройство: сливаем заново с его данными
                    continue
                }
            }

            stateStore.update { state in
                state.accountId = accountId
                state.reviewBase = merged.stats.reviewItems
            }
            return
        }
    }

    /// Удаляет данные в iCloud и на устройстве. Новое поколение всех групп удаляет данные
    /// и на других устройствах при их синхронизации; запись в iCloud остаётся пустой.
    /// - Parameter includeICloud: `false` — входа в iCloud нет, удаляются только данные устройства
    func deleteAllData(includeICloud: Bool) async throws {
        let now = Date.syncTimestamp
        var empty = SyncSnapshot()
        empty.displayName = Timestamped(value: nil, updatedAt: now)
        empty.avatar = Timestamped(value: "", updatedAt: now)
        empty.stats.epoch = .new(at: now)
        empty.achievementProgress.epoch = .new(at: now)
        empty.achievements.epoch = .new(at: now)
        empty.questionPool.epoch = .new(at: now)

        var accountId: String?
        if includeICloud {
            accountId = try await cloudService.accountId()
            for attempt in 1...maxSaveAttempts {
                let remote = try await cloudService.fetchProfileRecord()
                do {
                    try await cloudService.save(empty, to: remote?.record, avatar: .remove)
                    break
                } catch where error.isServerRecordChanged && attempt < maxSaveAttempts {
                    continue
                }
            }
        }

        wipeLocalData(epochs: empty)
        if let accountId {
            stateStore.update { $0.accountId = accountId }
        }
    }

    // MARK: - Local Snapshot

    private func makeLocalSnapshot(remote: SyncSnapshot?) -> SyncSnapshot {
        let state = stateStore.state
        let deviceId = state.deviceId
        let stats = statsManager.stats
        let exam = examStatisticsManager.statistics
        var snapshot = SyncSnapshot()

        if let profileProvider {
            snapshot.displayName = profileProvider.syncDisplayName
            snapshot.avatar = profileProvider.syncAvatar
        }

        // Свой вклад = итоги на устройстве − известные вклады других устройств
        let ownStats = Self.statsCounters(stats: stats, exam: exam) - state.otherStatsDevices.total()
        snapshot.stats = StatsSection(
            epoch: state.statsEpoch,
            devices: state.otherStatsDevices.merging(
                [deviceId: contribution(ownStats, remote: remote?.stats.devices[deviceId], seq: state.seq)]
            ) { _, own in own },
            lastQuiz: stats.lastQuizDate.map { LastQuiz(date: $0, percentage: stats.lastQuizPercentage) },
            recentQuizResults: stats.recentQuizResults,
            topicStreaks: stats.topicStats.mapValues {
                TopicStreak(streak: $0.streak, longestStreak: $0.longestStreak, lastUpdated: $0.lastUpdated)
            },
            reviewItems: statsManager.reviewSchedule.items,
            dailyProgress: statsManager.dailyProgress,
            exam: ExamSummary(
                lastExamDate: exam.lastExamDate,
                bestScore: exam.bestScore,
                currentStreak: exam.currentStreak,
                longestStreak: exam.longestStreak,
                history: exam.history
            )
        )

        let ownAchievementCounters = AchievementCounters(
            questionsStudied: stats.totalQuestionsStudied,
            quizzesCompleted: stats.totalQuizzesCompleted,
            perfectScores: stats.perfectScores
        ) - state.otherAchievementDevices.total()
        snapshot.achievementProgress = AchievementProgressSection(
            epoch: state.achievementProgressEpoch,
            devices: state.otherAchievementDevices.merging(
                [deviceId: contribution(ownAchievementCounters, remote: remote?.achievementProgress.devices[deviceId], seq: state.seq)]
            ) { _, own in own },
            winStreak: WinStreak(
                current: stats.currentStreak,
                longest: stats.longestStreak,
                updatedAt: stats.lastQuizDate ?? .distantPast
            )
        )

        snapshot.achievements = AchievementsSection(
            epoch: state.achievementsEpoch,
            unlocked: achievementManager.unlockedDates
        )
        snapshot.questionPool = QuestionPoolSection(
            epoch: state.questionPoolEpoch,
            usedIds: questionPoolProgressManager.getUsedIds(version: questionPoolVersion)
        )
        return snapshot
    }

    /// Неизменившийся вклад сохраняет номер отправки: снимок совпадёт с iCloud, и сохранять его не нужно
    private func contribution<Counters: SyncCounters>(
        _ counters: Counters,
        remote: DeviceContribution<Counters>?,
        seq: Int
    ) -> DeviceContribution<Counters> {
        if let remote, remote.counters == counters {
            return remote
        }
        return DeviceContribution(seq: max(seq, remote?.seq ?? 0) + 1, counters: counters)
    }

    static func statsCounters(stats: UserStats, exam: ExamStatistics) -> StatsCounters {
        StatsCounters(
            correctAnswers: stats.correctAnswers,
            incorrectAnswers: stats.incorrectAnswers,
            correctedMistakes: stats.correctedMistakes,
            topics: stats.topicStats.mapValues { AnswerCounter(correct: $0.correctAnswers, total: $0.totalAnswers) },
            difficulties: stats.difficultyStats.mapValues { AnswerCounter(correct: $0.correctAnswers, total: $0.totalAnswers) },
            examsCompleted: exam.totalExamsCompleted,
            examsPassed: exam.examsPassed,
            examsFailed: exam.examsFailed,
            examQuestionsAnswered: exam.totalQuestionsAnswered,
            examCorrectAnswers: exam.totalCorrectAnswers,
            examTimeSpent: exam.totalTimeSpent
        )
    }

    // MARK: - Apply

    /// Записывает слитый снимок в хранилища устройства
    private func apply(_ snapshot: SyncSnapshot) {
        let deviceId = stateStore.state.deviceId
        let poolEpochChanged = snapshot.questionPool.epoch != stateStore.state.questionPoolEpoch

        let totals: StatsCounters = snapshot.stats.devices.total()
        let achievementTotals: AchievementCounters = snapshot.achievementProgress.devices.total()
        let current = statsManager.stats

        var stats = UserStats()
        stats.correctAnswers = totals.correctAnswers
        stats.incorrectAnswers = totals.incorrectAnswers
        stats.correctedMistakes = totals.correctedMistakes
        stats.wrongQuestionIds = Set(snapshot.stats.reviewItems.keys)
        stats.lastQuizDate = snapshot.stats.lastQuiz?.date
        stats.lastActivityAt = snapshot.stats.lastQuiz?.date
        stats.lastQuizPercentage = snapshot.stats.lastQuiz?.percentage ?? 0
        stats.recentQuizResults = snapshot.stats.recentQuizResults
        stats.topicStats = Dictionary(uniqueKeysWithValues: Set(totals.topics.keys).union(snapshot.stats.topicStreaks.keys).map { topic in
            let counter = totals.topics[topic] ?? AnswerCounter()
            let streak = snapshot.stats.topicStreaks[topic]
            return (topic, TopicStat(
                correctAnswers: counter.correct,
                totalAnswers: counter.total,
                streak: streak?.streak ?? 0,
                longestStreak: streak?.longestStreak ?? 0,
                lastUpdated: streak?.lastUpdated
            ))
        })
        stats.difficultyStats = totals.difficulties.reduce(into: [:]) { result, entry in
            var stat = DifficultyStat(
                correctAnswers: entry.value.correct,
                totalAnswers: entry.value.total,
                lastUpdated: current.difficultyStats[entry.key]?.lastUpdated
            )
            stat.updateAdaptiveScore()
            result[entry.key] = stat
        }
        stats.totalQuestionsStudied = achievementTotals.questionsStudied
        stats.totalQuizzesCompleted = achievementTotals.quizzesCompleted
        stats.perfectScores = achievementTotals.perfectScores
        stats.currentStreak = snapshot.achievementProgress.winStreak.current
        stats.longestStreak = snapshot.achievementProgress.winStreak.longest

        statsManager.applySyncedState(
            stats: stats,
            reviewSchedule: ReviewSchedule(items: snapshot.stats.reviewItems),
            dailyProgress: snapshot.stats.dailyProgress
        )

        var exam = ExamStatistics()
        exam.totalExamsCompleted = totals.examsCompleted
        exam.examsPassed = totals.examsPassed
        exam.examsFailed = totals.examsFailed
        exam.totalQuestionsAnswered = totals.examQuestionsAnswered
        exam.totalCorrectAnswers = totals.examCorrectAnswers
        exam.totalTimeSpent = totals.examTimeSpent
        exam.averageScore = totals.examQuestionsAnswered > 0
            ? Double(totals.examCorrectAnswers) / Double(totals.examQuestionsAnswered) * 100
            : 0
        exam.bestScore = snapshot.stats.exam.bestScore
        exam.lastExamDate = snapshot.stats.exam.lastExamDate
        exam.currentStreak = snapshot.stats.exam.currentStreak
        exam.longestStreak = snapshot.stats.exam.longestStreak
        exam.history = snapshot.stats.exam.history
        examStatisticsManager.applySyncedStatistics(exam)

        questionPoolProgressManager.replaceUsedIds(snapshot.questionPool.usedIds, version: questionPoolVersion)
        if poolEpochChanged {
            // Банк начали заново на другом устройстве: режим повторения пройденного банка выключается
            questionPoolProgressManager.setReviewMode(false, version: questionPoolVersion)
        }
        achievementManager.applyUnlockedDates(snapshot.achievements.unlocked)

        stateStore.update { state in
            for section in SyncSection.allCases {
                state.setEpoch(snapshot.epoch(of: section), for: section)
            }
            state.otherStatsDevices = snapshot.stats.devices.filter { $0.key != deviceId }
            state.otherAchievementDevices = snapshot.achievementProgress.devices.filter { $0.key != deviceId }
            state.seq = max(
                state.seq,
                snapshot.stats.devices[deviceId]?.seq ?? 0,
                snapshot.achievementProgress.devices[deviceId]?.seq ?? 0
            )
        }
    }

    /// Имя и фото: новое фото из iCloud скачивается, удалённое — удаляется на устройстве
    private func applyProfile(_ snapshot: SyncSnapshot, localAvatarHash: String) async {
        guard let profileProvider else { return }
        if snapshot.displayName != profileProvider.syncDisplayName {
            profileProvider.applySyncedDisplayName(snapshot.displayName)
        }

        guard snapshot.avatar.value != localAvatarHash else {
            if snapshot.avatar != profileProvider.syncAvatar {
                profileProvider.applySyncedAvatar(snapshot.avatar, data: nil)
            }
            return
        }
        if snapshot.avatar.value.isEmpty {
            profileProvider.applySyncedAvatar(snapshot.avatar, data: nil)
            return
        }
        do {
            guard let data = try await cloudService.fetchAvatarData(),
                  AvatarImageProcessor.fingerprint(of: data) == snapshot.avatar.value else {
                return
            }
            profileProvider.applySyncedAvatar(snapshot.avatar, data: data)
        } catch {
            // Фото подтянется при следующей синхронизации
            AppLogger.warning("Failed to download avatar: \(error.localizedDescription)", category: AppLogger.data)
        }
    }

    /// Фото отправляется, только если победило фото устройства и в iCloud его ещё нет
    private func avatarUpload(merged: SyncSnapshot, remote: SyncSnapshot?, localAvatarHash: String) -> AvatarUpload {
        guard merged.avatar.value != remote?.avatar.value else { return .keep }
        if merged.avatar.value.isEmpty { return .remove }
        guard merged.avatar.value == localAvatarHash, let fileURL = profileProvider?.syncAvatarFileURL else {
            return .keep
        }
        return .upload(fileURL)
    }

    /// Очищает данные устройства и состояние синхронизации; идентификатор устройства сохраняется
    private func wipeLocalData(epochs snapshot: SyncSnapshot) {
        let deviceId = stateStore.state.deviceId
        stateStore.update { $0 = LocalSyncState(deviceId: deviceId) }
        var empty = SyncSnapshot()
        empty.stats.epoch = snapshot.stats.epoch
        empty.achievementProgress.epoch = snapshot.achievementProgress.epoch
        empty.achievements.epoch = snapshot.achievements.epoch
        empty.questionPool.epoch = snapshot.questionPool.epoch
        apply(empty)
        questionPoolProgressManager.setReviewMode(false, version: questionPoolVersion)
        profileProvider?.clearProfileForSync()
    }
}
