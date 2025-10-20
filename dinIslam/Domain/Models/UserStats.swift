//
//  UserStats.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

struct UserStats: Codable {
    var totalQuestionsStudied: Int = 0
    var correctAnswers: Int = 0
    var incorrectAnswers: Int = 0
    var wrongQuestionIds: Set<String> = []
    var lastQuizDate: Date?
    var totalQuizzesCompleted: Int = 0
    
    var accuracyPercentage: Double {
        guard totalQuestionsStudied > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestionsStudied) * 100
    }
    
    var wrongQuestionsCount: Int {
        return wrongQuestionIds.count
    }
    
    mutating func updateStats(correctCount: Int, totalCount: Int, wrongQuestionIds: [String]) {
        totalQuestionsStudied += totalCount
        correctAnswers += correctCount
        incorrectAnswers += (totalCount - correctCount)
        
        // Добавляем новые неправильные вопросы
        for id in wrongQuestionIds {
            self.wrongQuestionIds.insert(id)
        }
        
        lastQuizDate = Date()
        totalQuizzesCompleted += 1
    }
    
    mutating func clearWrongQuestions() {
        wrongQuestionIds.removeAll()
    }
    
    mutating func removeWrongQuestion(_ questionId: String) {
        wrongQuestionIds.remove(questionId)
    }
}
