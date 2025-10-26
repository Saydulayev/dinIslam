//
//  ExamUseCase.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

// MARK: - Exam Use Case Protocol
protocol ExamUseCaseProtocol {
    func startExam(configuration: ExamConfiguration, language: String) async throws -> [Question]
    func shuffleAnswers(for question: Question) -> Question
    func calculateExamResult(
        questions: [Question],
        answers: [String: ExamAnswer],
        configuration: ExamConfiguration,
        totalTimeSpent: TimeInterval
    ) -> ExamResult
    func loadExamQuestions(language: String, count: Int) async throws -> [Question]
}

// MARK: - Exam Answer
struct ExamAnswer: Codable, Equatable {
    let questionId: String
    let selectedAnswerIndex: Int?
    let isSkipped: Bool
    let timeSpent: TimeInterval
    let isTimeExpired: Bool
    
    init(questionId: String, selectedAnswerIndex: Int? = nil, isSkipped: Bool = false, timeSpent: TimeInterval = 0, isTimeExpired: Bool = false) {
        self.questionId = questionId
        self.selectedAnswerIndex = selectedAnswerIndex
        self.isSkipped = isSkipped
        self.timeSpent = timeSpent
        self.isTimeExpired = isTimeExpired
    }
    
    var isCorrect: Bool {
        guard let selectedIndex = selectedAnswerIndex, !isSkipped, !isTimeExpired else {
            return false
        }
        // This will be determined by comparing with the correct answer index
        return true // Placeholder - will be set by ExamUseCase
    }
}

// MARK: - Exam Use Case Implementation
@MainActor
class ExamUseCase: ExamUseCaseProtocol {
    private let questionsRepository: QuestionsRepositoryProtocol
    private let examStatisticsManager: ExamStatisticsManager
    
    init(questionsRepository: QuestionsRepositoryProtocol, examStatisticsManager: ExamStatisticsManager) {
        self.questionsRepository = questionsRepository
        self.examStatisticsManager = examStatisticsManager
    }
    
    func startExam(configuration: ExamConfiguration, language: String) async throws -> [Question] {
        let questions = try await loadExamQuestions(language: language, count: configuration.totalQuestions)
        return questions.map { shuffleAnswers(for: $0) }
    }
    
    func shuffleAnswers(for question: Question) -> Question {
        let shuffledAnswers = question.answers.shuffled()
        let correctAnswer = question.answers[question.correctIndex]
        
        // Find new index of correct answer
        let newCorrectIndex = shuffledAnswers.firstIndex { $0.id == correctAnswer.id } ?? 0
        
        return Question(
            id: question.id,
            text: question.text,
            answers: shuffledAnswers,
            correctIndex: newCorrectIndex,
            category: question.category,
            difficulty: question.difficulty
        )
    }
    
    func calculateExamResult(
        questions: [Question],
        answers: [String: ExamAnswer],
        configuration: ExamConfiguration,
        totalTimeSpent: TimeInterval
    ) -> ExamResult {
        var answeredQuestions = 0
        var skippedQuestions = 0
        var correctAnswers = 0
        var incorrectAnswers = 0
        var timeExpiredQuestions = 0
        var totalQuestionTime: TimeInterval = 0
        
        for question in questions {
            guard let answer = answers[question.id] else {
                skippedQuestions += 1
                continue
            }
            
            totalQuestionTime += answer.timeSpent
            
            if answer.isTimeExpired {
                timeExpiredQuestions += 1
                skippedQuestions += 1
            } else if answer.isSkipped {
                skippedQuestions += 1
            } else if let selectedIndex = answer.selectedAnswerIndex {
                answeredQuestions += 1
                if selectedIndex == question.correctIndex {
                    correctAnswers += 1
                } else {
                    incorrectAnswers += 1
                }
            } else {
                skippedQuestions += 1
            }
        }
        
        let percentage = answeredQuestions > 0 ? Double(correctAnswers) / Double(answeredQuestions) * 100 : 0
        let averageTimePerQuestion = answeredQuestions > 0 ? totalQuestionTime / Double(answeredQuestions) : 0
        
        return ExamResult(
            totalQuestions: questions.count,
            answeredQuestions: answeredQuestions,
            skippedQuestions: skippedQuestions,
            correctAnswers: correctAnswers,
            incorrectAnswers: incorrectAnswers,
            timeExpiredQuestions: timeExpiredQuestions,
            totalTimeSpent: totalTimeSpent,
            averageTimePerQuestion: averageTimePerQuestion,
            percentage: percentage,
            configuration: configuration,
            completedAt: Date()
        )
    }
    
    func loadExamQuestions(language: String, count: Int) async throws -> [Question] {
        let allQuestions = try await questionsRepository.loadQuestions(language: language)
        
        // Filter questions by difficulty for exam mode
        let examQuestions = allQuestions.filter { question in
            // In exam mode, prefer medium and hard questions
            question.difficulty == .medium || question.difficulty == .hard
        }
        
        // If not enough medium/hard questions, include easy ones
        let finalQuestions = examQuestions.count >= count ? 
            Array(examQuestions.prefix(count)) :
            Array(allQuestions.prefix(count))
        
        return finalQuestions.shuffled()
    }
}

// MARK: - Exam Statistics Manager
@MainActor
@Observable
class ExamStatisticsManager {
    var statistics: ExamStatistics
    private let userDefaults = UserDefaults.standard
    private let statisticsKey = "ExamStatistics"
    
    init() {
        self.statistics = Self.loadStatistics()
    }
    
    func updateStatistics(with result: ExamResult) {
        statistics.updateStatistics(with: result)
        saveStatistics()
    }
    
    func resetStatistics() {
        statistics = ExamStatistics()
        saveStatistics()
    }
    
    private func saveStatistics() {
        if let encoded = try? JSONEncoder().encode(statistics) {
            userDefaults.set(encoded, forKey: statisticsKey)
        }
    }
    
    private static func loadStatistics() -> ExamStatistics {
        guard let data = UserDefaults.standard.data(forKey: "ExamStatistics"),
              let statistics = try? JSONDecoder().decode(ExamStatistics.self, from: data) else {
            return ExamStatistics()
        }
        return statistics
    }
}
