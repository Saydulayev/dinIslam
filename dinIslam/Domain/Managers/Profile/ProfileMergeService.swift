//
//  ProfileMergeService.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class ProfileMergeService {
    private let adaptiveEngine: AdaptiveLearningEngine
    
    init(adaptiveEngine: AdaptiveLearningEngine) {
        self.adaptiveEngine = adaptiveEngine
    }
    
    func mergeProfile(local: UserProfile, remote: UserProfile, strategy: ProfileMergeStrategy) -> UserProfile {
        var merged = remote

        switch strategy {
        case .preferLocal:
            merged.fullName = local.fullName ?? remote.fullName
            merged.email = local.email ?? remote.email
            merged.customDisplayName = local.customDisplayName ?? remote.customDisplayName
            merged.preferences = mergePreferences(remote: remote.preferences, local: local.preferences, preferLocal: true)
            merged.progress = mergeProgress(remote: remote.progress, local: local.progress, preferLocal: true)
            merged.avatarURL = local.avatarURL ?? merged.avatarURL
        case .preferRemote:
            merged.fullName = remote.fullName ?? local.fullName
            merged.email = remote.email ?? local.email
            merged.customDisplayName = remote.customDisplayName ?? local.customDisplayName
            merged.preferences = mergePreferences(remote: remote.preferences, local: local.preferences, preferLocal: false)
            merged.progress = mergeProgress(remote: remote.progress, local: local.progress, preferLocal: false)
            merged.avatarURL = remote.avatarURL ?? local.avatarURL
        case .newest:
            let preferLocal = (local.metadata.updatedAt > remote.metadata.updatedAt)
            // Сохраняем fullName, email и customDisplayName, предпочитая непустые значения
            merged.fullName = preferLocal ? 
                (local.fullName ?? remote.fullName) : 
                (remote.fullName ?? local.fullName)
            merged.email = preferLocal ? 
                (local.email ?? remote.email) : 
                (remote.email ?? local.email)
            merged.customDisplayName = preferLocal ? 
                (local.customDisplayName ?? remote.customDisplayName) : 
                (remote.customDisplayName ?? local.customDisplayName)
            merged.preferences = mergePreferences(remote: remote.preferences, local: local.preferences, preferLocal: preferLocal)
            merged.progress = mergeProgress(remote: remote.progress, local: local.progress, preferLocal: preferLocal)
            merged.avatarURL = preferLocal
                ? (local.avatarURL ?? remote.avatarURL)
                : (remote.avatarURL ?? local.avatarURL)
        }

        merged.metadata.updatedAt = Date()
        merged.metadata.lastSyncedAt = Date()
        merged.metadata.lastDeviceIdentifier = UIDeviceIdentifierProvider.currentIdentifier()
        return merged
    }

    // MARK: - Private Helpers
    private func mergePreferences(remote: ProfilePreferences, local: ProfilePreferences, preferLocal: Bool) -> ProfilePreferences {
        ProfilePreferences(
            preferredDifficulty: preferLocal ? (local.preferredDifficulty ?? remote.preferredDifficulty) : (remote.preferredDifficulty ?? local.preferredDifficulty),
            dailyGoal: preferLocal ? local.dailyGoal : remote.dailyGoal,
            notificationsEnabled: preferLocal ? local.notificationsEnabled : remote.notificationsEnabled,
            syncedSettings: preferLocal ? local.syncedSettings : remote.syncedSettings,
            preferredStudyTopics: preferLocal ? (local.preferredStudyTopics.isEmpty ? remote.preferredStudyTopics : local.preferredStudyTopics) : (remote.preferredStudyTopics.isEmpty ? local.preferredStudyTopics : remote.preferredStudyTopics)
        )
    }

    private func mergeProgress(remote: ProfileProgress, local: ProfileProgress, preferLocal: Bool) -> ProfileProgress {
        var merged = remote

        if preferLocal {
            merged.totalQuestionsAnswered = max(remote.totalQuestionsAnswered, local.totalQuestionsAnswered)
            merged.correctAnswers = max(remote.correctAnswers, local.correctAnswers)
            merged.incorrectAnswers = max(remote.incorrectAnswers, local.incorrectAnswers)
            merged.correctedMistakes = max(remote.correctedMistakes, local.correctedMistakes)
            merged.examsTaken = max(remote.examsTaken, local.examsTaken)
            merged.examsPassed = max(remote.examsPassed, local.examsPassed)
            merged.currentStreak = max(remote.currentStreak, local.currentStreak)
            merged.longestStreak = max(remote.longestStreak, local.longestStreak)
            merged.averageQuizScore = max(remote.averageQuizScore, local.averageQuizScore)
        } else {
            merged.totalQuestionsAnswered = max(remote.totalQuestionsAnswered, local.totalQuestionsAnswered)
            merged.correctAnswers = max(remote.correctAnswers, local.correctAnswers)
            merged.incorrectAnswers = max(remote.incorrectAnswers, local.incorrectAnswers)
            merged.correctedMistakes = max(remote.correctedMistakes, local.correctedMistakes)
            merged.examsTaken = max(remote.examsTaken, local.examsTaken)
            merged.examsPassed = max(remote.examsPassed, local.examsPassed)
            merged.currentStreak = max(remote.currentStreak, local.currentStreak)
            merged.longestStreak = max(remote.longestStreak, local.longestStreak)
            merged.averageQuizScore = max(remote.averageQuizScore, local.averageQuizScore)
        }

        merged.difficultyStats = mergeDifficultyStats(remote: remote.difficultyStats, local: local.difficultyStats)
        merged.topicProgress = mergeTopicProgress(remote: remote.topicProgress, local: local.topicProgress)
        merged.quizHistory = mergeQuizHistory(remote: remote.quizHistory, local: local.quizHistory)
        merged.examHistory = mergeExamHistory(remote: remote.examHistory, local: local.examHistory)
        let latestActivity = max(remote.lastActivityAt ?? .distantPast, local.lastActivityAt ?? .distantPast)
        merged.lastActivityAt = latestActivity == .distantPast ? nil : latestActivity
        merged.recommendations = adaptiveEngine.generateRecommendations(for: merged)
        merged.masteryLevel = adaptiveEngine.computeOverallMastery(
            averageScore: merged.averageQuizScore,
            streak: merged.currentStreak
        )
        return merged
    }

    private func mergeDifficultyStats(remote: [DifficultyPerformance], local: [DifficultyPerformance]) -> [DifficultyPerformance] {
        var dictionary: [Difficulty: DifficultyPerformance] = [:]
        for stat in remote {
            dictionary[stat.difficulty] = stat
        }
        for stat in local {
            if var existing = dictionary[stat.difficulty] {
                existing.totalAnswers = max(existing.totalAnswers, stat.totalAnswers)
                existing.correctAnswers = max(existing.correctAnswers, stat.correctAnswers)
                existing.adaptiveScore = max(existing.adaptiveScore, stat.adaptiveScore)
                existing.masteryLevel = maxMastery(existing.masteryLevel, stat.masteryLevel)
                dictionary[stat.difficulty] = existing
            } else {
                dictionary[stat.difficulty] = stat
            }
        }
        return Array(dictionary.values)
    }

    private func mergeTopicProgress(remote: [TopicProgress], local: [TopicProgress]) -> [TopicProgress] {
        var dictionary: [String: TopicProgress] = [:]
        for topic in remote {
            dictionary[topic.topicId] = topic
        }
        for topic in local {
            if var existing = dictionary[topic.topicId] {
                existing.totalAnswers = max(existing.totalAnswers, topic.totalAnswers)
                existing.correctAnswers = max(existing.correctAnswers, topic.correctAnswers)
                existing.streak = max(existing.streak, topic.streak)
                existing.masteryLevel = maxMastery(existing.masteryLevel, topic.masteryLevel)
                existing.recommendedDifficulty = topic.recommendedDifficulty ?? existing.recommendedDifficulty
                existing.lastActivityAt = max(existing.lastActivityAt ?? .distantPast, topic.lastActivityAt ?? .distantPast)
                dictionary[topic.topicId] = existing
            } else {
                dictionary[topic.topicId] = topic
            }
        }
        return Array(dictionary.values)
    }

    private func maxMastery(_ lhs: MasteryLevel, _ rhs: MasteryLevel) -> MasteryLevel {
        if lhs == rhs { return lhs }
        let order: [MasteryLevel] = [.novice, .learning, .proficient, .expert]
        guard let idxL = order.firstIndex(of: lhs),
              let idxR = order.firstIndex(of: rhs) else {
            return lhs
        }
        return idxL > idxR ? lhs : rhs
    }

    private func mergeQuizHistory(remote: [QuizHistoryEntry], local: [QuizHistoryEntry]) -> [QuizHistoryEntry] {
        var dictionary: [UUID: QuizHistoryEntry] = [:]
        for entry in remote {
            dictionary[entry.id] = entry
        }
        for entry in local {
            dictionary[entry.id] = entry
        }
        let merged = dictionary.values.sorted { $0.date > $1.date }
        return Array(merged.prefix(20))
    }

    private func mergeExamHistory(remote: [ExamHistoryEntry], local: [ExamHistoryEntry]) -> [ExamHistoryEntry] {
        var dictionary: [UUID: ExamHistoryEntry] = [:]
        for entry in remote {
            dictionary[entry.id] = entry
        }
        for entry in local {
            dictionary[entry.id] = entry
        }
        let merged = dictionary.values.sorted { $0.date > $1.date }
        return Array(merged.prefix(20))
    }
}

