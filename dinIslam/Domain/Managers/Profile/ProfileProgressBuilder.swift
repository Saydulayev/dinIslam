//
//  ProfileProgressBuilder.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class ProfileProgressBuilder {
    private let adaptiveEngine: AdaptiveLearningEngine
    private let statsManager: StatsManager
    private let examStatisticsManager: ExamStatisticsManager
    
    init(
        adaptiveEngine: AdaptiveLearningEngine,
        statsManager: StatsManager,
        examStatisticsManager: ExamStatisticsManager
    ) {
        self.adaptiveEngine = adaptiveEngine
        self.statsManager = statsManager
        self.examStatisticsManager = examStatisticsManager
    }
    
    func rebuildProgressFromLocalStats(profile: inout UserProfile) {
        var progress = profile.progress
        let stats = statsManager.stats
        let examStats = examStatisticsManager.statistics

        progress.totalQuestionsAnswered = stats.totalQuestionsStudied
        progress.correctAnswers = stats.correctAnswers
        progress.incorrectAnswers = stats.incorrectAnswers
        progress.correctedMistakes = stats.correctedMistakes
        progress.currentStreak = stats.currentStreak
        progress.longestStreak = stats.longestStreak
        progress.averageQuizScore = stats.averageRecentScore
        progress.lastActivityAt = stats.lastQuizDate

        progress.examsTaken = examStats.totalExamsCompleted
        progress.examsPassed = examStats.examsPassed

        progress.difficultyStats = stats.difficultyStats.compactMap { key, value in
            guard let difficulty = Difficulty(rawValue: key) else { return nil }
            return DifficultyPerformance(
                difficulty: difficulty,
                correctAnswers: value.correctAnswers,
                totalAnswers: value.totalAnswers,
                adaptiveScore: value.adaptiveScore,
                masteryLevel: masteryLevel(for: value.adaptiveScore)
            )
        }

        progress.topicProgress = stats.topicStats.map { key, value in
            TopicProgress(
                topicId: key,
                displayName: key,
                correctAnswers: value.correctAnswers,
                totalAnswers: value.totalAnswers,
                masteryLevel: masteryLevel(for: value.accuracy),
                streak: value.streak,
                recommendedDifficulty: recommendedDifficulty(for: masteryLevel(for: value.accuracy)),
                lastActivityAt: value.lastUpdated
            )
        }

        progress.quizHistory = stats.recentQuizResults.map { record in
            let correctCount = Int((record.percentage / 100.0) * Double(record.questionsCount))
            return QuizHistoryEntry(
                date: record.date,
                percentage: record.percentage,
                correctAnswers: correctCount,
                totalQuestions: record.questionsCount,
                difficultyBreakdown: [:],
                topicBreakdown: [:]
            )
        }

        progress.examHistory = progress.examHistory.filter { entry in
            examStats.lastExamDate == nil || entry.date <= (examStats.lastExamDate ?? entry.date)
        }

        progress.masteryLevel = adaptiveEngine.computeOverallMastery(
            averageScore: progress.averageQuizScore,
            streak: progress.currentStreak
        )
        progress.recommendations = adaptiveEngine.generateRecommendations(for: progress)

        profile.progress = progress
        profile.metadata.updatedAt = Date()
    }
    
    func syncProgressToLocalStats(profile: UserProfile) {
        // Переносим данные из ProfileProgress обратно в локальные StatsManager и ExamStatisticsManager
        statsManager.updateFromProfileProgress(profile.progress, quizHistory: profile.progress.quizHistory)
        examStatisticsManager.updateFromProfileProgress(profile.progress, examHistory: profile.progress.examHistory)
    }
    
    // MARK: - Private Helpers
    private func masteryLevel(for accuracy: Double) -> MasteryLevel {
        switch accuracy {
        case ..<50:
            return .novice
        case 50..<70:
            return .learning
        case 70..<90:
            return .proficient
        default:
            return .expert
        }
    }

    private func recommendedDifficulty(for mastery: MasteryLevel) -> Difficulty? {
        switch mastery {
        case .novice:
            return .easy
        case .learning:
            return .medium
        case .proficient, .expert:
            return .hard
        }
    }
}

