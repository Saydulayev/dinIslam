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
    func isBankCompleted(language: String) async throws -> (isCompleted: Bool, totalQuestions: Int, studiedCount: Int)
    func markQuestionsUsed(_ questionIds: [String])
}

class QuizUseCase: QuizUseCaseProtocol {
    private let questionsRepository: QuestionsRepositoryProtocol
    private let profileProgressProvider: ProfileProgressProviding
    private let questionSelectionStrategy: QuestionSelectionStrategy
    private let fallbackStrategy: QuestionSelectionStrategy
    private let questionPoolProgressManager: QuestionPoolProgressManaging
    private let questionPoolVersion = 1
    
    init(
        questionsRepository: QuestionsRepositoryProtocol,
        profileProgressProvider: ProfileProgressProviding,
        questionSelectionStrategy: QuestionSelectionStrategy,
        fallbackStrategy: QuestionSelectionStrategy? = nil,
        questionPoolProgressManager: QuestionPoolProgressManaging
    ) {
        self.questionsRepository = questionsRepository
        self.profileProgressProvider = profileProgressProvider
        self.questionSelectionStrategy = questionSelectionStrategy
        self.fallbackStrategy = fallbackStrategy ?? FallbackQuestionSelectionStrategy()
        self.questionPoolProgressManager = questionPoolProgressManager
    }
    
    func startQuiz(language: String) async throws -> [Question] {
        let allQuestions = try await questionsRepository.loadQuestions(language: language)
        let currentQuestionIds = Set(allQuestions.map { $0.id })
        let used = questionPoolProgressManager.getUsedIds(version: questionPoolVersion)
        let isReviewMode = questionPoolProgressManager.isReviewMode(version: questionPoolVersion)
        let isCompleted = questionPoolProgressManager.isBankCompleted(
            currentQuestionIds: currentQuestionIds,
            version: questionPoolVersion
        )
        
        // Если банк завершён и не в режиме повторения, возвращаем пустой массив (показываем экран завершения)
        if isCompleted && !isReviewMode {
            return []
        }
        
        let sessionCount = min(20, allQuestions.count) // Адаптивный размер сессии
        
        // В режиме изучения (не reviewMode) выбираем только новые вопросы
        if !isReviewMode {
            let newQuestions = allQuestions.filter { !used.contains($0.id) }
            let actualSessionCount = min(sessionCount, newQuestions.count)
            
            // Используем адаптивную стратегию только для новых вопросов
            var selected = questionSelectionStrategy.selectQuestions(
                from: allQuestions,
                progress: profileProgressProvider.progress,
                usedQuestionIds: used,
                sessionCount: actualSessionCount
            )
            
            // Фильтруем только новые вопросы (без повторов)
            selected = selected.filter { !used.contains($0.id) }
            
            // Если не набрали достаточно, используем fallback только для новых
            if selected.count < actualSessionCount {
                let alreadySelectedIds = Set(selected.map { $0.id })
                let remainingNewQuestions = allQuestions.filter { 
                    !used.contains($0.id) && !alreadySelectedIds.contains($0.id)
                }
                let remainingNeeded = actualSessionCount - selected.count
                
                let fallbackSelected = Array(remainingNewQuestions.shuffled().prefix(remainingNeeded))
                selected.append(contentsOf: fallbackSelected)
            }
            
            // Ограничиваем размер сессии количеством оставшихся новых вопросов
            let finalSelected = Array(selected.prefix(actualSessionCount))
            // НЕ помечаем как использованные здесь - только при завершении викторины
            return finalSelected
        } else {
            // Режим повторения: используем текущую логику с повторами
            var selected = questionSelectionStrategy.selectQuestions(
                from: allQuestions,
                progress: profileProgressProvider.progress,
                usedQuestionIds: used,
                sessionCount: sessionCount
            )
            
            // If not enough questions, use fallback strategy
            if selected.count < sessionCount {
                let alreadySelectedIds = Set(selected.map { $0.id })
                let remainingQuestions = allQuestions.filter { !alreadySelectedIds.contains($0.id) }
                let remainingNeeded = sessionCount - selected.count
                
                let fallbackSelected = fallbackStrategy.selectQuestions(
                    from: remainingQuestions,
                    progress: profileProgressProvider.progress,
                    usedQuestionIds: used.union(alreadySelectedIds),
                    sessionCount: remainingNeeded
                )
                
                selected.append(contentsOf: fallbackSelected)
            }
            
            // НЕ помечаем как использованные здесь - только при завершении викторины
            return selected
        }
    }
    
    func markQuestionsUsed(_ questionIds: [String]) {
        questionPoolProgressManager.markUsed(questionIds, version: questionPoolVersion)
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
        let currentQuestionIds = Set(allQuestions.map { $0.id })
        let stats = questionPoolProgressManager.getProgressStats(
            total: allQuestions.count,
            currentQuestionIds: currentQuestionIds,
            version: questionPoolVersion
        )
        
        return (
            total: allQuestions.count,
            used: stats.used,
            remaining: stats.remaining
        )
    }
    
    func isBankCompleted(language: String) async throws -> (isCompleted: Bool, totalQuestions: Int, studiedCount: Int) {
        let allQuestions = try await questionsRepository.loadQuestions(language: language)
        let currentQuestionIds = Set(allQuestions.map { $0.id })
        let totalQuestions = allQuestions.count
        let isCompleted = questionPoolProgressManager.isBankCompleted(
            currentQuestionIds: currentQuestionIds,
            version: questionPoolVersion
        )
        let stats = questionPoolProgressManager.getProgressStats(
            total: totalQuestions,
            currentQuestionIds: currentQuestionIds,
            version: questionPoolVersion
        )
        
        return (
            isCompleted: isCompleted,
            totalQuestions: totalQuestions,
            studiedCount: stats.used
        )
    }
}
