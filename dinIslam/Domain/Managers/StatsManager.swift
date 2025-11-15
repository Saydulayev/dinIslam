//
//  StatsManager.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Observation

@MainActor
@Observable
class StatsManager {
    weak var profileSyncDelegate: ProfileProgressSyncDelegate?
    var stats: UserStats
    
    private let userDefaults = UserDefaults.standard
    private let statsKey = "UserStats"
    
    init() {
        self.stats = Self.loadStats()
    }
    
    private static func loadStats() -> UserStats {
        guard let data = UserDefaults.standard.data(forKey: "UserStats"),
              let stats = try? JSONDecoder().decode(UserStats.self, from: data) else {
            return UserStats()
        }
        return stats
    }
    
    func recordQuizSession(_ summary: QuizSessionSummary) {
        stats.recordQuizSession(summary)
        saveStats()
        profileSyncDelegate?.statsManager(self, didRecord: summary)
    }
    
    func clearWrongQuestions() {
        stats.clearWrongQuestions()
        saveStats()
    }
    
    func removeWrongQuestion(_ questionId: String) {
        stats.removeWrongQuestion(questionId)
        saveStats()
        // Уведомляем делегата об обновлении статистики для синхронизации с ProfileManager
        profileSyncDelegate?.statsManagerDidUpdate(self)
    }
    
    func getWrongQuestions(from allQuestions: [Question]) -> [Question] {
        return allQuestions.filter { stats.wrongQuestionIds.contains($0.id) }
    }

    private func saveStats() {
        if let data = try? JSONEncoder().encode(stats) {
            userDefaults.set(data, forKey: statsKey)
        }
    }
    
    func resetStats() {
        stats = UserStats()
        saveStats()
        profileSyncDelegate?.statsManagerDidReset(self)
    }
    
    func resetStatsExceptTotalQuestions() {
        stats = UserStats()
        saveStats()
        profileSyncDelegate?.statsManagerDidReset(self)
    }
    
    func getCorrectedMistakesCount() -> Int {
        return stats.correctedMistakes
    }
    
    // MARK: - Recent Score Methods
    
    func getAverageRecentScore() -> Double {
        return stats.averageRecentScore
    }
    
    func getRecentGamesCount() -> Int {
        return stats.recentGamesCount
    }
    
    func hasRecentGames() -> Bool {
        return !stats.recentQuizResults.isEmpty
    }

    // MARK: - Achievements-related reset
    func resetAchievementProgress() {
        // Сбрасываем только метрики, влияющие на прогресс достижений
        stats.totalQuestionsStudied = 0
        stats.totalQuizzesCompleted = 0
        stats.currentStreak = 0
        stats.perfectScores = 0
        stats.longestStreak = 0
        saveStats()
        profileSyncDelegate?.statsManagerDidReset(self)
    }
    
    // MARK: - Profile Progress Sync
    func updateFromProfileProgress(_ progress: ProfileProgress, quizHistory: [QuizHistoryEntry]) {
        // Сохраняем wrongQuestionIds, чтобы не потерять их при обновлении
        let preservedWrongQuestionIds = stats.wrongQuestionIds
        
        // Обновляем основные метрики
        stats.totalQuestionsStudied = progress.totalQuestionsAnswered
        stats.correctAnswers = progress.correctAnswers
        stats.incorrectAnswers = progress.incorrectAnswers
        stats.correctedMistakes = progress.correctedMistakes
        stats.currentStreak = progress.currentStreak
        stats.longestStreak = progress.longestStreak
        stats.lastActivityAt = progress.lastActivityAt
        stats.lastQuizDate = progress.lastActivityAt
        
        // Восстанавливаем wrongQuestionIds (они не синхронизируются с CloudKit, остаются локальными)
        stats.wrongQuestionIds = preservedWrongQuestionIds
        
        // Обновляем recentQuizResults из quizHistory
        stats.recentQuizResults = quizHistory.prefix(10).map { entry in
            QuizResultRecord(
                percentage: entry.percentage,
                date: entry.date,
                questionsCount: entry.totalQuestions
            )
        }
        
        // Обновляем topicStats из topicProgress
        stats.topicStats = Dictionary(uniqueKeysWithValues: progress.topicProgress.map { topic in
            (topic.topicId, TopicStat(
                correctAnswers: topic.correctAnswers,
                totalAnswers: topic.totalAnswers,
                streak: topic.streak,
                longestStreak: topic.streak, // Используем текущий streak как longest, так как в TopicProgress нет longestStreak
                lastUpdated: topic.lastActivityAt
            ))
        })
        
        // Обновляем difficultyStats из difficultyStats
        stats.difficultyStats = Dictionary(uniqueKeysWithValues: progress.difficultyStats.map { difficulty in
            (difficulty.difficulty.rawValue, DifficultyStat(
                correctAnswers: difficulty.correctAnswers,
                totalAnswers: difficulty.totalAnswers,
                adaptiveScore: difficulty.adaptiveScore,
                lastUpdated: nil // В DifficultyPerformance нет lastUpdated
            ))
        })
        
        // Вычисляем totalQuizzesCompleted из quizHistory
        stats.totalQuizzesCompleted = quizHistory.count
        
        // averageRecentScore вычисляется автоматически через computed property в UserStats
        
        saveStats()
    }
}

protocol ProfileProgressSyncDelegate: AnyObject {
    func statsManager(_ manager: StatsManager, didRecord summary: QuizSessionSummary)
    func statsManagerDidReset(_ manager: StatsManager)
    func statsManagerDidUpdate(_ manager: StatsManager)
}
