//
//  QuizUseCase.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

protocol QuizUseCaseProtocol {
    func startQuiz(language: String) async throws -> [Question]
    func loadAllQuestions(language: String) async throws -> [Question]
    func shuffleAnswers(for question: Question) -> Question
    func calculateResult(correctAnswers: Int, totalQuestions: Int, timeSpent: TimeInterval) -> QuizResult
}

class QuizUseCase: QuizUseCaseProtocol {
    private let questionsRepository: QuestionsRepositoryProtocol
    private let questionPoolVersion = 1
    
    init(questionsRepository: QuestionsRepositoryProtocol) {
        self.questionsRepository = questionsRepository
    }
    
    func startQuiz(language: String) async throws -> [Question] {
        let allQuestions = try await questionsRepository.loadQuestions(language: language)
        let progress = QuestionPoolProgress(version: questionPoolVersion)
        let used = progress.usedIds
        let unusedQuestions = allQuestions.filter { !used.contains($0.id) }
        
        let sessionCount = min(20, allQuestions.count) // Адаптивный размер сессии
        var selected: [Question] = []
        
        if unusedQuestions.count >= sessionCount {
            // Достаточно новых вопросов - берем только их
            selected = Array(unusedQuestions.shuffled().prefix(sessionCount))
            print("📚 Using \(selected.count) new questions")
            print("📋 New question IDs: \(selected.map { $0.id }.joined(separator: ", "))")
        } else if unusedQuestions.count > 0 {
            // Частично новые + некоторые повторные
            selected = Array(unusedQuestions.shuffled())
            let remaining = sessionCount - unusedQuestions.count
            let repeatedQuestions = allQuestions.filter { used.contains($0.id) }
            let additional = Array(repeatedQuestions.shuffled().prefix(remaining))
            selected.append(contentsOf: additional)
            print("📚 Using \(unusedQuestions.count) new + \(additional.count) repeated questions")
            print("📋 New question IDs: \(unusedQuestions.map { $0.id }.joined(separator: ", "))")
            print("📋 Repeated question IDs: \(additional.map { $0.id }.joined(separator: ", "))")
        } else {
            // Все вопросы пройдены - начинаем заново
            progress.reset(for: questionPoolVersion)
            selected = Array(allQuestions.shuffled().prefix(sessionCount))
            print("🔄 All questions completed, starting fresh with \(selected.count) questions")
            print("📋 Fresh question IDs: \(selected.map { $0.id }.joined(separator: ", "))")
        }
        
        progress.markUsed(selected.map { $0.id })
        return selected
    }
    
    func shuffleAnswers(for question: Question) -> Question {
        let shuffledAnswers = question.answers.shuffled()
        let correctAnswer = question.answers[question.correctIndex]
        
        // Find the new index of the correct answer
        guard let newCorrectIndex = shuffledAnswers.firstIndex(where: { $0.id == correctAnswer.id }) else {
            return question
        }
        
        return Question(
            id: question.id,
            text: question.text,
            answers: shuffledAnswers,
            correctIndex: newCorrectIndex,
            category: question.category,
            difficulty: question.difficulty
        )
    }
    
    func loadAllQuestions(language: String) async throws -> [Question] {
        return try await questionsRepository.loadQuestions(language: language)
    }
    
    func calculateResult(correctAnswers: Int, totalQuestions: Int, timeSpent: TimeInterval) -> QuizResult {
        let percentage = totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) * 100 : 0
        return QuizResult(
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
            percentage: percentage,
            timeSpent: timeSpent
        )
    }
    
    func getProgressStats(language: String) async throws -> (total: Int, used: Int, remaining: Int) {
        let allQuestions = try await questionsRepository.loadQuestions(language: language)
        let progress = QuestionPoolProgress(version: questionPoolVersion)
        let usedCount = progress.usedIds.count
        let remainingCount = allQuestions.count - usedCount
        
        return (
            total: allQuestions.count,
            used: usedCount,
            remaining: remainingCount
        )
    }
}
