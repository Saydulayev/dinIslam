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
    var correctedMistakes: Int = 0  // Новое поле для исправленных ошибок
    var wrongQuestionIds: Set<String> = []
    var lastQuizDate: Date?
    var totalQuizzesCompleted: Int = 0
    var currentStreak: Int = 0  // Текущая серия побед
    var perfectScores: Int = 0  // Количество идеальных результатов
    var lastQuizPercentage: Double = 0  // Процент последней викторины
    
    var accuracyPercentage: Double {
        guard totalQuestionsStudied > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestionsStudied) * 100
    }
    
    var wrongQuestionsCount: Int {
        return wrongQuestionIds.count
    }
    
    mutating func updateStats(correctCount: Int, totalCount: Int, wrongQuestionIds: [String], percentage: Double = 0) {
        totalQuestionsStudied += totalCount
        correctAnswers += correctCount
        incorrectAnswers += (totalCount - correctCount)
        
        // Добавляем новые неправильные вопросы
        for id in wrongQuestionIds {
            self.wrongQuestionIds.insert(id)
        }
        
        lastQuizDate = Date()
        totalQuizzesCompleted += 1
        lastQuizPercentage = percentage
        
        // Обновляем серию побед
        if percentage >= 80.0 {
            currentStreak += 1
        } else {
            currentStreak = 0
        }
        
        // Обновляем идеальные результаты
        if percentage == 100.0 {
            perfectScores += 1
        }
    }
    
    mutating func clearWrongQuestions() {
        wrongQuestionIds.removeAll()
    }
    
    mutating func removeWrongQuestion(_ questionId: String) {
        if wrongQuestionIds.remove(questionId) != nil {
            correctedMistakes += 1
        }
    }
}
