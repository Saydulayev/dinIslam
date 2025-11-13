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
}

protocol ProfileProgressSyncDelegate: AnyObject {
    func statsManager(_ manager: StatsManager, didRecord summary: QuizSessionSummary)
    func statsManagerDidReset(_ manager: StatsManager)
}
