//
//  UserStats.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

// MARK: - Quiz Result Record
struct QuizResultRecord: Codable, Equatable {
    let percentage: Double
    let date: Date
    let questionsCount: Int
    
    init(percentage: Double, date: Date, questionsCount: Int) {
        self.percentage = percentage
        self.date = date
        self.questionsCount = questionsCount
    }
}

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
    var longestStreak: Int = 0
    var lastQuizPercentage: Double = 0  // Процент последней викторины
    var recentQuizResults: [QuizResultRecord] = []  // Последние 10 результатов
    var topicStats: [String: TopicStat] = [:]
    var difficultyStats: [String: DifficultyStat] = [:]
    var lastActivityAt: Date?
    
    var accuracyPercentage: Double {
        guard totalQuestionsStudied > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestionsStudied) * 100
    }
    
    var averageRecentScore: Double {
        guard !recentQuizResults.isEmpty else { return 0 }
        let sum = recentQuizResults.reduce(0) { $0 + $1.percentage }
        return sum / Double(recentQuizResults.count)
    }
    
    var recentGamesCount: Int {
        return recentQuizResults.count
    }
    
    var wrongQuestionsCount: Int {
        return wrongQuestionIds.count
    }
    
    mutating func recordQuizSession(_ summary: QuizSessionSummary) {
        totalQuestionsStudied += summary.totalQuestions
        correctAnswers += summary.correctAnswers
        incorrectAnswers += summary.incorrectAnswers

        // Добавляем новые неправильные вопросы
        let wrongQuestionIds = summary.outcomes.filter { !$0.isCorrect }.map(\.questionId)
        for id in wrongQuestionIds {
            self.wrongQuestionIds.insert(id)
        }

        lastQuizDate = summary.completedAt
        totalQuizzesCompleted += 1
        lastQuizPercentage = summary.percentage
        lastActivityAt = summary.completedAt

        // Добавляем результат в массив последних игр
        let newResult = QuizResultRecord(
            percentage: summary.percentage,
            date: summary.completedAt,
            questionsCount: summary.totalQuestions
        )
        recentQuizResults.insert(newResult, at: 0) // Добавляем в начало

        // Ограничиваем массив до 10 элементов
        if recentQuizResults.count > 10 {
            recentQuizResults.removeLast()
        }

        // Обновляем серию побед
        if summary.percentage >= 80.0 {
            currentStreak += 1
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        } else {
            currentStreak = 0
        }

        // Обновляем идеальные результаты (используем >= 99.99 для учета погрешности округления)
        if summary.percentage >= 99.99 {
            perfectScores += 1
        }

        // Обновляем статистику по темам и сложностям
        for outcome in summary.outcomes {
            var topicStat = topicStats[outcome.category] ?? TopicStat()
            topicStat.totalAnswers += 1
            if outcome.isCorrect {
                topicStat.correctAnswers += 1
                topicStat.streak += 1
                if topicStat.streak > topicStat.longestStreak {
                    topicStat.longestStreak = topicStat.streak
                }
            } else {
                topicStat.streak = 0
            }
            topicStat.lastUpdated = summary.completedAt
            topicStats[outcome.category] = topicStat

            let difficultyKey = outcome.difficulty.rawValue
            var difficultyStat = difficultyStats[difficultyKey] ?? DifficultyStat()
            difficultyStat.totalAnswers += 1
            if outcome.isCorrect {
                difficultyStat.correctAnswers += 1
            }
            difficultyStat.lastUpdated = summary.completedAt
            difficultyStat.updateAdaptiveScore()
            difficultyStats[difficultyKey] = difficultyStat
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

// MARK: - Extended Stats
struct TopicStat: Codable {
    var correctAnswers: Int = 0
    var totalAnswers: Int = 0
    var streak: Int = 0
    var longestStreak: Int = 0
    var lastUpdated: Date?

    var accuracy: Double {
        guard totalAnswers > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAnswers) * 100
    }
}

struct DifficultyStat: Codable {
    var correctAnswers: Int = 0
    var totalAnswers: Int = 0
    var adaptiveScore: Double = 0
    var lastUpdated: Date?

    mutating func updateAdaptiveScore() {
        guard totalAnswers > 0 else {
            adaptiveScore = 0
            return
        }
        adaptiveScore = Double(correctAnswers) / Double(totalAnswers) * 100
    }
}
