//
//  StatsManager.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Combine

class StatsManager: ObservableObject {
    @Published var stats: UserStats
    
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
    
    func updateStats(correctCount: Int, totalCount: Int, wrongQuestionIds: [String]) {
        stats.updateStats(correctCount: correctCount, totalCount: totalCount, wrongQuestionIds: wrongQuestionIds)
        saveStats()
    }
    
    func clearWrongQuestions() {
        stats.clearWrongQuestions()
        saveStats()
    }
    
    func removeWrongQuestion(_ questionId: String) {
        print("DEBUG: StatsManager.removeWrongQuestion called with ID: \(questionId)")
        print("DEBUG: Wrong questions before removal: \(stats.wrongQuestionIds.count)")
        stats.removeWrongQuestion(questionId)
        print("DEBUG: Wrong questions after removal: \(stats.wrongQuestionIds.count)")
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
    }
    
    func getCorrectedMistakesCount() -> Int {
        return stats.correctedMistakes
    }
}
