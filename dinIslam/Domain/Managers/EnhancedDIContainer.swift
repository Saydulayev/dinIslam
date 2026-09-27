//
//  EnhancedDIContainer.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

// MARK: - Enhanced Dependency Injection Container (Factory)
class EnhancedDIContainer {
    // MARK: - Factory Methods
    static func createEnhancedDependencies(baseDependencies: AppDependenciesProtocol? = nil) -> EnhancedDependencies {
        let base = baseDependencies ?? AppDependencies()
        return EnhancedDependencies(baseDependencies: base)
    }
}

// MARK: - Enhanced Dependencies
/// Uses the same questions service as AppDependencies, so the whole app shares one cache and one network manager.
struct EnhancedDependencies {
    let baseDependencies: AppDependenciesProtocol
    let enhancedQuizUseCase: EnhancedQuizUseCaseProtocol
    
    init(baseDependencies: AppDependenciesProtocol) {
        self.baseDependencies = baseDependencies
        self.enhancedQuizUseCase = EnhancedQuizUseCase(
            questionsRepository: baseDependencies.questionsRepository,
            networkManager: baseDependencies.networkManager,
            adaptiveEngine: baseDependencies.adaptiveLearningEngine,
            profileManager: baseDependencies.profileManager,
            questionPoolProgressManager: baseDependencies.questionPoolProgressManager
        )
    }
}

// MARK: - Enhanced Quiz Use Case Protocol
protocol EnhancedQuizUseCaseProtocol {
    func startQuiz(language: String) async throws -> [Question]
    func loadAllQuestions(language: String) async throws -> [Question]
    func shuffleAnswers(for question: Question) -> Question
    func calculateResult(correctAnswers: Int, totalQuestions: Int, timeSpent: TimeInterval) -> QuizResult
    func preloadQuestions(for languages: [String]) async
    func getCacheStatus() -> CacheStatus
    func clearCache() async
    func isBankCompleted(language: String) async throws -> (isCompleted: Bool, totalQuestions: Int, studiedCount: Int)
    func markQuestionsUsed(_ questionIds: [String])
    
    // Update checking
    func checkForUpdates(language: String) async
    func hasUpdates() -> Bool
    func forceSync(language: String) async -> [Question]
}

// MARK: - Enhanced Quiz Use Case
class EnhancedQuizUseCase: EnhancedQuizUseCaseProtocol {
    private let questionsRepository: EnhancedQuestionsRepositoryProtocol
    private let networkManager: NetworkManager
    private let adaptiveEngine: AdaptiveLearningEngine
    private let profileManager: ProfileManager
    private let questionPoolProgressManager: QuestionPoolProgressManaging
    private let questionPoolVersion = 1
    
    init(
        questionsRepository: EnhancedQuestionsRepositoryProtocol,
        networkManager: NetworkManager,
        adaptiveEngine: AdaptiveLearningEngine,
        profileManager: ProfileManager,
        questionPoolProgressManager: QuestionPoolProgressManaging? = nil
    ) {
        self.questionsRepository = questionsRepository
        self.networkManager = networkManager
        self.adaptiveEngine = adaptiveEngine
        self.profileManager = profileManager
        self.questionPoolProgressManager = questionPoolProgressManager ?? DefaultQuestionPoolProgressManager()
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
        
        let sessionCount = min(20, allQuestions.count)
        
        // В режиме изучения (не reviewMode) выбираем только новые вопросы
        if !isReviewMode {
            let newQuestions = allQuestions.filter { !used.contains($0.id) }
            let actualSessionCount = min(sessionCount, newQuestions.count)
            
            var selected = adaptiveEngine.selectQuestions(
                from: allQuestions,
                progress: profileManager.progress,
                usedQuestionIds: used,
                sessionCount: actualSessionCount
            )
            
            // Фильтруем только новые вопросы (без повторов)
            selected = selected.filter { !used.contains($0.id) }
            
            // Если не набрали достаточно, добавляем оставшиеся новые
            if selected.count < actualSessionCount {
                let alreadySelectedIds = Set(selected.map { $0.id })
                let remainingNewQuestions = allQuestions.filter { question in
                    !used.contains(question.id) && !alreadySelectedIds.contains(question.id)
                }
                if !remainingNewQuestions.isEmpty {
                    let remainingNeeded = actualSessionCount - selected.count
                    selected.append(contentsOf: Array(remainingNewQuestions.shuffled().prefix(remainingNeeded)))
                }
            }
            
            // Ограничиваем размер сессии количеством оставшихся новых вопросов
            let finalSelected = Array(selected.prefix(actualSessionCount))
            // НЕ помечаем как использованные здесь - только при завершении викторины
            return finalSelected
        } else {
            // Режим повторения: используем текущую логику с повторами
            var selected = adaptiveEngine.selectQuestions(
                from: allQuestions,
                progress: profileManager.progress,
                usedQuestionIds: used,
                sessionCount: sessionCount
            )
            
            if selected.count < sessionCount {
                let remainingNewQuestions = allQuestions.filter { question in
                    !used.contains(question.id) && !selected.contains(where: { $0.id == question.id })
                }
                if !remainingNewQuestions.isEmpty {
                    let remainingNeeded = sessionCount - selected.count
                    selected.append(contentsOf: Array(remainingNewQuestions.shuffled().prefix(remainingNeeded)))
                }
            }
            
            if selected.count < sessionCount {
                let fallback = allQuestions.filter { question in
                    !selected.contains(where: { $0.id == question.id })
                }
                let remainingNeeded = sessionCount - selected.count
                selected.append(contentsOf: Array(fallback.shuffled().prefix(remainingNeeded)))
            }
            
            // НЕ помечаем как использованные здесь - только при завершении викторины
            return selected
        }
    }
    
    func markQuestionsUsed(_ questionIds: [String]) {
        questionPoolProgressManager.markUsed(questionIds, version: questionPoolVersion)
    }
    
    func shuffleAnswers(for question: Question) -> Question {
        guard question.correctIndex >= 0, question.correctIndex < question.answers.count else {
            return question
        }
        let shuffledAnswers = question.answers.shuffled()
        let correctAnswer = question.answers[question.correctIndex]
        
        guard let newCorrectIndex = shuffledAnswers.firstIndex(where: { $0.id == correctAnswer.id }) else {
            return question
        }
        
        return question.withAnswers(shuffledAnswers, correctIndex: newCorrectIndex)
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
    
    func preloadQuestions(for languages: [String]) async {
        await questionsRepository.preloadQuestions(for: languages)
    }
    
    func getCacheStatus() -> CacheStatus {
        return questionsRepository.getCacheStatus()
    }
    
    func clearCache() async {
        await questionsRepository.clearCache()
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
    
    func checkForUpdates(language: String) async {
        await questionsRepository.checkForUpdates(language: language)
    }
    
    func hasUpdates() -> Bool {
        return questionsRepository.hasUpdates()
    }
    
    func forceSync(language: String) async -> [Question] {
        return await questionsRepository.forceSync(language: language)
    }
}
