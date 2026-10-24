//
//  SyncMerger.swift
//  dinIslam
//
//  Слияние снимка устройства со снимком из iCloud. Слияние выполняется на каждом устройстве
//  и даёт одинаковый результат независимо от порядка: повторная синхронизация ничего не меняет.
//

import Foundation

enum SyncMerger {
    /// - Parameters:
    ///   - local: снимок устройства: вклады других устройств — из прошлой синхронизации, свой — текущий
    ///   - remote: снимок из iCloud (`nil` — записи ещё нет)
    ///   - reviewBase: ошибки на момент последней успешной синхронизации — по ним видно,
    ///     что изменилось на устройстве, а что в iCloud
    ///   - deviceId: это устройство: свой вклад берётся из `local`
    static func merge(
        local: SyncSnapshot,
        remote: SyncSnapshot?,
        reviewBase: [String: ReviewItem],
        deviceId: String
    ) -> SyncSnapshot {
        guard let remote else { return local }

        var merged = SyncSnapshot()
        merged.displayName = latest(local: local.displayName, remote: remote.displayName)
        merged.avatar = latest(local: local.avatar, remote: remote.avatar)
        merged.stats = mergeStats(local: local.stats, remote: remote.stats, reviewBase: reviewBase, deviceId: deviceId)
        merged.achievementProgress = mergeAchievementProgress(local: local.achievementProgress, remote: remote.achievementProgress, deviceId: deviceId)
        merged.achievements = mergeAchievements(local: local.achievements, remote: remote.achievements)
        merged.questionPool = mergeQuestionPool(local: local.questionPool, remote: remote.questionPool)
        return merged
    }

    // MARK: - Fields

    /// При равном времени побеждает iCloud: иначе два устройства с одинаковым временем
    /// по очереди перезаписывали бы друг друга
    static func latest<Value>(local: Timestamped<Value>, remote: Timestamped<Value>) -> Timestamped<Value> {
        local.updatedAt > remote.updatedAt ? local : remote
    }

    /// Новое поколение заменяет данные старого; `nil` — поколения совпадают, данные нужно сливать
    private static func newerGeneration<Section>(
        local: Section,
        remote: Section,
        epoch: (Section) -> SyncEpoch
    ) -> Section? {
        let localEpoch = epoch(local)
        let remoteEpoch = epoch(remote)
        guard localEpoch != remoteEpoch else { return nil }
        return localEpoch.isNewer(than: remoteEpoch) ? local : remote
    }

    static func mergeDevices<Counters>(
        local: [String: DeviceContribution<Counters>],
        remote: [String: DeviceContribution<Counters>],
        deviceId: String
    ) -> [String: DeviceContribution<Counters>] {
        var merged = remote
        for (id, contribution) in local {
            guard let remoteContribution = remote[id] else {
                merged[id] = contribution
                continue
            }
            // Свой вклад устройство знает лучше всех; при равном seq — его копия
            let localWins = id == deviceId
                ? contribution.seq >= remoteContribution.seq
                : contribution.seq > remoteContribution.seq
            if localWins {
                merged[id] = contribution
            }
        }
        return merged
    }

    // MARK: - Sections

    private static func mergeStats(
        local: StatsSection,
        remote: StatsSection,
        reviewBase: [String: ReviewItem],
        deviceId: String
    ) -> StatsSection {
        if let winner = newerGeneration(local: local, remote: remote, epoch: \.epoch) {
            return winner
        }

        var merged = StatsSection(epoch: local.epoch)
        merged.devices = mergeDevices(local: local.devices, remote: remote.devices, deviceId: deviceId)
        merged.lastQuiz = [local.lastQuiz, remote.lastQuiz].compactMap { $0 }.max { $0.date < $1.date }
        merged.recentQuizResults = mergeRecentResults(local.recentQuizResults, remote.recentQuizResults)
        merged.topicStreaks = mergeTopicStreaks(local.topicStreaks, remote.topicStreaks)
        merged.reviewItems = mergeReviewItems(local: local.reviewItems, remote: remote.reviewItems, base: reviewBase)
        merged.dailyProgress = DailyProgress.merged(local.dailyProgress, remote.dailyProgress)
        merged.exam = mergeExam(local.exam, remote.exam)
        return merged
    }

    private static func mergeAchievementProgress(
        local: AchievementProgressSection,
        remote: AchievementProgressSection,
        deviceId: String
    ) -> AchievementProgressSection {
        if let winner = newerGeneration(local: local, remote: remote, epoch: \.epoch) {
            return winner
        }

        var merged = AchievementProgressSection(epoch: local.epoch)
        merged.devices = mergeDevices(local: local.devices, remote: remote.devices, deviceId: deviceId)
        let newer = local.winStreak.updatedAt > remote.winStreak.updatedAt ? local.winStreak : remote.winStreak
        merged.winStreak = WinStreak(
            current: newer.current,
            longest: max(local.winStreak.longest, remote.winStreak.longest),
            updatedAt: newer.updatedAt
        )
        return merged
    }

    private static func mergeAchievements(local: AchievementsSection, remote: AchievementsSection) -> AchievementsSection {
        if let winner = newerGeneration(local: local, remote: remote, epoch: \.epoch) {
            return winner
        }
        // Достижение открыто, если открыто на любом устройстве; дата — самая ранняя
        let unlocked = local.unlocked.merging(remote.unlocked) { min($0, $1) }
        return AchievementsSection(epoch: local.epoch, unlocked: unlocked)
    }

    private static func mergeQuestionPool(local: QuestionPoolSection, remote: QuestionPoolSection) -> QuestionPoolSection {
        if let winner = newerGeneration(local: local, remote: remote, epoch: \.epoch) {
            return winner
        }
        return QuestionPoolSection(epoch: local.epoch, usedIds: local.usedIds.union(remote.usedIds))
    }

    // MARK: - Stats Values

    static func mergeRecentResults(_ local: [QuizResultRecord], _ remote: [QuizResultRecord]) -> [QuizResultRecord] {
        var seen = Set<String>()
        return (local + remote)
            .sorted { $0.date > $1.date }
            .filter { seen.insert("\($0.date.timeIntervalSinceReferenceDate)|\($0.percentage)|\($0.questionsCount)").inserted }
            .prefix(10)
            .map { $0 }
    }

    private static func mergeTopicStreaks(_ local: [String: TopicStreak], _ remote: [String: TopicStreak]) -> [String: TopicStreak] {
        local.merging(remote) { localStreak, remoteStreak in
            let localDate = localStreak.lastUpdated ?? .distantPast
            let remoteDate = remoteStreak.lastUpdated ?? .distantPast
            let newer = localDate > remoteDate ? localStreak : remoteStreak
            return TopicStreak(
                streak: newer.streak,
                longestStreak: max(localStreak.longestStreak, remoteStreak.longestStreak),
                lastUpdated: newer.lastUpdated
            )
        }
    }

    private static func mergeExam(_ local: ExamSummary, _ remote: ExamSummary) -> ExamSummary {
        let localDate = local.lastExamDate ?? .distantPast
        let remoteDate = remote.lastExamDate ?? .distantPast
        let newer = localDate > remoteDate ? local : remote
        return ExamSummary(
            lastExamDate: newer.lastExamDate,
            bestScore: max(local.bestScore, remote.bestScore),
            currentStreak: newer.currentStreak,
            longestStreak: max(local.longestStreak, remote.longestStreak),
            history: mergeExamHistory(local.history, remote.history)
        )
    }

    static func mergeExamHistory(_ local: [ExamHistoryRecord], _ remote: [ExamHistoryRecord]) -> [ExamHistoryRecord] {
        var seen = Set<String>()
        return (local + remote)
            .sorted { $0.date > $1.date }
            .filter { seen.insert("\($0.date.timeIntervalSinceReferenceDate)|\($0.percentage)|\($0.totalQuestions)").inserted }
            .prefix(ExamStatistics.historyLimit)
            .map { $0 }
    }

    /// Трёхстороннее слияние ошибок: берётся сторона, изменившая вопрос с прошлой синхронизации.
    /// Если вопрос изменили обе стороны, он остаётся в ошибках на самом раннем этапе повторения —
    /// лишний раз повторить лучше, чем потерять ошибку.
    static func mergeReviewItems(
        local: [String: ReviewItem],
        remote: [String: ReviewItem],
        base: [String: ReviewItem]
    ) -> [String: ReviewItem] {
        var merged: [String: ReviewItem] = [:]
        for id in Set(local.keys).union(remote.keys) {
            let localItem = local[id]
            let remoteItem = remote[id]
            let baseItem = base[id]

            let result: ReviewItem?
            if localItem == remoteItem {
                result = localItem
            } else if localItem == baseItem {
                result = remoteItem
            } else if remoteItem == baseItem {
                result = localItem
            } else {
                result = [localItem, remoteItem].compactMap { $0 }.min {
                    $0.stage != $1.stage ? $0.stage < $1.stage : $0.dueDate < $1.dueDate
                }
            }
            merged[id] = result
        }
        return merged
    }
}
