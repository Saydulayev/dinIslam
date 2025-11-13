//
//  ProfileProgressContext.swift
//  dinIslam
//
//  Created by GPT-5 Codex on 09.11.25.
//

import Foundation

struct QuizQuestionOutcome: Codable, Equatable {
    let questionId: String
    let category: String
    let difficulty: Difficulty
    let isCorrect: Bool
}

struct QuizSessionSummary: Codable, Equatable {
    let correctAnswers: Int
    let totalQuestions: Int
    let percentage: Double
    let duration: TimeInterval
    let completedAt: Date
    let outcomes: [QuizQuestionOutcome]

    var incorrectAnswers: Int {
        return totalQuestions - correctAnswers
    }

    var topicBreakdown: [String: Int] {
        outcomes.reduce(into: [:]) { partialResult, outcome in
            guard !outcome.isCorrect else { return }
            partialResult[outcome.category, default: 0] += 1
        }
    }

    var difficultyBreakdown: [Difficulty: Int] {
        outcomes.reduce(into: [:]) { partialResult, outcome in
            partialResult[outcome.difficulty, default: 0] += 1
        }
    }
}

struct ExamSessionSummary: Codable, Equatable {
    let result: ExamResult
    let duration: TimeInterval
    let completedAt: Date

    var percentage: Double {
        result.percentage
    }

    var correctAnswers: Int {
        result.correctAnswers
    }

    var totalQuestions: Int {
        result.totalQuestions
    }

    var passed: Bool {
        result.isPassed
    }
}

