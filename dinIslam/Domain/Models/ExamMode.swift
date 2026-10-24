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
    
    static let `default` = ExamConfiguration(
        timePerQuestion: 30.0, // 30 секунд на вопрос
        totalQuestions: 20,
        allowSkip: true,
        showTimer: true
    )
    
    static let quick = ExamConfiguration(
        timePerQuestion: 15.0, // 15 секунд на вопрос
        totalQuestions: 10,
        allowSkip: false,
        showTimer: true
    )
    
    static let extended = ExamConfiguration(
        timePerQuestion: 60.0, // 1 минута на вопрос
        totalQuestions: 30,
        allowSkip: true,
        showTimer: true
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
    /// Вопросы закончились, есть пропущенные: вернуться к ним или завершить
    case skippedPrompt
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

enum ExamTimerUrgency: Equatable {
    case normal
    case warning
    case critical
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
    
    // Процент правильных ответов от отвеченных вопросов (для аналитики)
    var accuracyPercentage: Double {
        guard answeredQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(answeredQuestions) * 100
    }
    
    // Основной процент для отображения - от общего количества вопросов
    var overallPercentage: Double {
        return percentage
    }
    
    /// Проходной порог — от всех вопросов экзамена
    static let passingPercentage = 70.0
    
    /// Пропуск считается неверным ответом: он снижает процент, но сам по себе не означает провал
    var isPassed: Bool {
        percentage >= Self.passingPercentage
    }
    
    var grade: ExamGrade {
        ExamGrade(percentage: percentage)
    }
}

// MARK: - Exam History
/// Запись истории экзаменов
struct ExamHistoryRecord: Codable, Equatable, Identifiable {
    let date: Date
    let totalQuestions: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
    let skippedQuestions: Int
    let percentage: Double
    let timeSpent: TimeInterval
    
    var id: Date { date }
    
    var isPassed: Bool {
        percentage >= ExamResult.passingPercentage
    }
    
    var grade: ExamGrade {
        ExamGrade(percentage: percentage)
    }
    
    init(
        date: Date,
        totalQuestions: Int,
        correctAnswers: Int,
        incorrectAnswers: Int,
        skippedQuestions: Int,
        percentage: Double,
        timeSpent: TimeInterval
    ) {
        self.date = date
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.incorrectAnswers = incorrectAnswers
        self.skippedQuestions = skippedQuestions
        self.percentage = percentage
        self.timeSpent = timeSpent
    }
    
    init(result: ExamResult) {
        self.init(
            date: result.completedAt,
            totalQuestions: result.totalQuestions,
            correctAnswers: result.correctAnswers,
            incorrectAnswers: result.incorrectAnswers,
            skippedQuestions: result.skippedQuestions,
            percentage: result.percentage,
            timeSpent: result.totalTimeSpent
        )
    }
}

// MARK: - Exam Grade
enum ExamGrade: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case satisfactory = "satisfactory"
    case unsatisfactory = "unsatisfactory"
    
    /// Оценка по проценту правильных ответов от общего количества вопросов
    init(percentage: Double) {
        switch percentage {
        case 90...:
            self = .excellent
        case 80..<90:
            self = .good
        case 70..<80:
            self = .satisfactory
        default:
            self = .unsatisfactory
        }
    }
    
    var localizedName: String {
        switch self {
        case .excellent:
            return "exam.grade.excellent".localized
        case .good:
            return "exam.grade.good".localized
        case .satisfactory:
            return "exam.grade.satisfactory".localized
        case .unsatisfactory:
            return "exam.grade.unsatisfactory".localized
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
    /// Последние экзамены, новые — первыми
    var history: [ExamHistoryRecord] = []
    
    static let historyLimit = 50
    
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
        
        // Update best score - используем процент от общего количества вопросов
        if result.percentage > bestScore {
            bestScore = result.percentage
        }
        
        // Update average score
        // Без единого ответа деление дало бы NaN, а JSONEncoder его не сохраняет
        averageScore = totalQuestionsAnswered > 0
            ? Double(totalCorrectAnswers) / Double(totalQuestionsAnswered) * 100
            : 0
        
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
        
        history.insert(ExamHistoryRecord(result: result), at: 0)
        if history.count > Self.historyLimit {
            history.removeLast(history.count - Self.historyLimit)
        }
    }
}

// MARK: - Decoding
// Отсутствующее поле получает значение по умолчанию, а не обнуляет статистику экзаменов
// (см. StoredDataDecoding.swift)
extension ExamStatistics {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalExamsCompleted = container.decode(.totalExamsCompleted, default: 0)
        totalQuestionsAnswered = container.decode(.totalQuestionsAnswered, default: 0)
        totalCorrectAnswers = container.decode(.totalCorrectAnswers, default: 0)
        totalTimeSpent = container.decode(.totalTimeSpent, default: 0)
        bestScore = container.decode(.bestScore, default: 0)
        averageScore = container.decode(.averageScore, default: 0)
        examsPassed = container.decode(.examsPassed, default: 0)
        examsFailed = container.decode(.examsFailed, default: 0)
        lastExamDate = container.decodeOptional(.lastExamDate)
        currentStreak = container.decode(.currentStreak, default: 0)
        longestStreak = container.decode(.longestStreak, default: 0)
        history = container.decodeLossyArray(.history)
    }
}

extension ExamHistoryRecord {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        totalQuestions = container.decode(.totalQuestions, default: 0)
        correctAnswers = container.decode(.correctAnswers, default: 0)
        incorrectAnswers = container.decode(.incorrectAnswers, default: 0)
        skippedQuestions = container.decode(.skippedQuestions, default: 0)
        percentage = container.decode(.percentage, default: 0)
        timeSpent = container.decode(.timeSpent, default: 0)
    }
}
