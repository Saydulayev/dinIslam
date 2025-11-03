//
//  ExamMode.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

// MARK: - Exam Configuration
struct ExamConfiguration: Codable, Equatable {
    let timePerQuestion: TimeInterval
    let totalQuestions: Int
    let allowSkip: Bool
    let showTimer: Bool
    let autoSubmit: Bool
    
    static let `default` = ExamConfiguration(
        timePerQuestion: 30.0, // 30 секунд на вопрос
        totalQuestions: 20,
        allowSkip: true,
        showTimer: true,
        autoSubmit: true
    )
    
    static let quick = ExamConfiguration(
        timePerQuestion: 15.0, // 15 секунд на вопрос
        totalQuestions: 10,
        allowSkip: false,
        showTimer: true,
        autoSubmit: true
    )
    
    static let extended = ExamConfiguration(
        timePerQuestion: 60.0, // 1 минута на вопрос
        totalQuestions: 30,
        allowSkip: true,
        showTimer: true,
        autoSubmit: true
    )
}

// MARK: - Exam Question State
struct ExamQuestionState: Equatable {
    let questionId: String
    let timeRemaining: TimeInterval
    let isAnswered: Bool
    let selectedAnswerIndex: Int?
    let isSkipped: Bool
    let timeSpent: TimeInterval
    
    init(questionId: String, timeRemaining: TimeInterval) {
        self.questionId = questionId
        self.timeRemaining = timeRemaining
        self.isAnswered = false
        self.selectedAnswerIndex = nil
        self.isSkipped = false
        self.timeSpent = 0
    }
}

// MARK: - Exam State
enum ExamState: Equatable {
    case idle
    case active(ActiveExamState)
    case completed(CompletedExamState)
    case error(ExamErrorState)
}

enum ActiveExamState: Equatable {
    case loading
    case playing
    case paused
    case timeUp
}

enum CompletedExamState: Equatable {
    case finished
    case timeExpired
    case manuallyStopped
}

enum ExamErrorState: Equatable {
    case networkError
    case dataError
    case timerError
    case unknownError
}

// MARK: - Exam Result
struct ExamResult: Codable, Equatable {
    let totalQuestions: Int
    let answeredQuestions: Int
    let skippedQuestions: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
    let timeExpiredQuestions: Int
    let totalTimeSpent: TimeInterval
    let averageTimePerQuestion: TimeInterval
    let percentage: Double
    let configuration: ExamConfiguration
    let completedAt: Date
    
    var accuracyPercentage: Double {
        guard answeredQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(answeredQuestions) * 100
    }
    
    var isPassed: Bool {
        // Экзамен считается сданным только если:
        // 1. Все вопросы были отвечены (нет пропущенных)
        // 2. Процент правильных ответов >= 70%
        guard skippedQuestions == 0 else {
            // Если есть пропущенные вопросы, экзамен не сдан
            return false
        }
        return accuracyPercentage >= 70.0 // 70% для прохождения экзамена
    }
    
    var grade: ExamGrade {
        switch accuracyPercentage {
        case 90...100:
            return .excellent
        case 80..<90:
            return .good
        case 70..<80:
            return .satisfactory
        default:
            return .unsatisfactory
        }
    }
}

// MARK: - Exam Grade
enum ExamGrade: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case satisfactory = "satisfactory"
    case unsatisfactory = "unsatisfactory"
    
    var localizedName: String {
        switch self {
        case .excellent:
            return NSLocalizedString("exam.grade.excellent", comment: "Excellent grade")
        case .good:
            return NSLocalizedString("exam.grade.good", comment: "Good grade")
        case .satisfactory:
            return NSLocalizedString("exam.grade.satisfactory", comment: "Satisfactory grade")
        case .unsatisfactory:
            return NSLocalizedString("exam.grade.unsatisfactory", comment: "Unsatisfactory grade")
        }
    }
    
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .satisfactory:
            return "orange"
        case .unsatisfactory:
            return "red"
        }
    }
}

// MARK: - Exam Statistics
struct ExamStatistics: Codable {
    var totalExamsCompleted: Int = 0
    var totalQuestionsAnswered: Int = 0
    var totalCorrectAnswers: Int = 0
    var totalTimeSpent: TimeInterval = 0
    var bestScore: Double = 0
    var averageScore: Double = 0
    var examsPassed: Int = 0
    var examsFailed: Int = 0
    var lastExamDate: Date?
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    
    var passRate: Double {
        guard totalExamsCompleted > 0 else { return 0 }
        return Double(examsPassed) / Double(totalExamsCompleted) * 100
    }
    
    var averageTimePerQuestion: TimeInterval {
        guard totalQuestionsAnswered > 0 else { return 0 }
        return totalTimeSpent / Double(totalQuestionsAnswered)
    }
    
    mutating func updateStatistics(with result: ExamResult) {
        totalExamsCompleted += 1
        totalQuestionsAnswered += result.answeredQuestions
        totalCorrectAnswers += result.correctAnswers
        totalTimeSpent += result.totalTimeSpent
        lastExamDate = result.completedAt
        
        // Update best score
        if result.accuracyPercentage > bestScore {
            bestScore = result.accuracyPercentage
        }
        
        // Update average score
        averageScore = Double(totalCorrectAnswers) / Double(totalQuestionsAnswered) * 100
        
        // Update pass/fail count
        if result.isPassed {
            examsPassed += 1
            currentStreak += 1
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        } else {
            examsFailed += 1
            currentStreak = 0
        }
    }
}
