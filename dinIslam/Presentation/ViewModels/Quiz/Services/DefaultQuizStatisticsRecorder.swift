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
    
    func getWrongQuestions(from allQuestions: [Question]) -> [Question] {
        statsManager.getWrongQuestions(from: allQuestions)
    }
    
    func removeWrongQuestion(_ questionId: String) {
        statsManager.removeWrongQuestion(questionId)
    }
}

