//
//  DefaultQuizStatisticsRecorder.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class DefaultQuizStatisticsRecorder: QuizStatisticsRecording {
    private let statsManager: StatsManager
    
    var stats: UserStats {
        statsManager.stats
    }
    
    init(statsManager: StatsManager) {
        self.statsManager = statsManager
    }
    
    func recordQuizSession(_ summary: QuizSessionSummary) {
        statsManager.recordQuizSession(summary)
    }
    
    var dayStreak: Int {
        statsManager.dayStreak
    }
    
    func registerDailyGoal() {
        statsManager.registerDailyGoal()
    }
    
    func getWrongQuestions(from allQuestions: [Question], scope: MistakesReviewScope) -> [Question] {
        switch scope {
        case .due:
            return statsManager.getDueWrongQuestions(from: allQuestions)
        case .all:
            return statsManager.getWrongQuestions(from: allQuestions)
        case .questions(let ids):
            return allQuestions.filter { ids.contains($0.id) }
        }
    }
    
    func recordReviewAnswers(_ answers: [String: Bool]) -> ReviewSessionSummary {
        statsManager.recordReviewAnswers(answers)
    }
}

