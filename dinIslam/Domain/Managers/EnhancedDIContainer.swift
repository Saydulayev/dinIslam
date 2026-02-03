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
    
    // MARK: - Backward Compatibility (Deprecated)
    @available(*, deprecated, message: "Use EnhancedDIContainer.createEnhancedDependencies() instead")
    static let shared: EnhancedDIContainer = {
        let container = EnhancedDIContainer()
        let baseDeps = AppDependencies()
        container._dependencies = EnhancedDependencies(baseDependencies: baseDeps)
        return container
    }()
    
    private var _dependencies: EnhancedDependencies?
    
    private init() {}
    
    // MARK: - Lazy Properties for Backward Compatibility
    var networkManager: NetworkManager {
        _dependencies?.networkManager ?? EnhancedDependencies(baseDependencies: AppDependencies()).networkManager
    }
    
    var networkConfiguration: NetworkConfiguration {
        _dependencies?.networkConfiguration ?? EnhancedDependencies(baseDependencies: AppDependencies()).networkConfiguration
    }
    
    var cacheManager: CacheManager {
        _dependencies?.cacheManager ?? EnhancedDependencies(baseDependencies: AppDependencies()).cacheManager
    }
    
    var cacheConfiguration: CacheConfiguration {
        _dependencies?.cacheConfiguration ?? EnhancedDependencies(baseDependencies: AppDependencies()).cacheConfiguration
    }
    
    var settingsManager: SettingsManager {
        _dependencies?.baseDependencies.settingsManager ?? AppDependencies().settingsManager
    }
    
    var statsManager: StatsManager {
        _dependencies?.baseDependencies.statsManager ?? AppDependencies().statsManager
    }
    
    var examStatisticsManager: ExamStatisticsManager {
        _dependencies?.baseDependencies.examStatisticsManager ?? AppDependencies().examStatisticsManager
    }

    var adaptiveLearningEngine: AdaptiveLearningEngine {
        _dependencies?.baseDependencies.adaptiveLearningEngine ?? AppDependencies().adaptiveLearningEngine
    }

    var profileManager: ProfileManager {
        _dependencies?.baseDependencies.profileManager ?? AppDependencies().profileManager
    }
    
    var achievementManager: AchievementManager {
        _dependencies?.baseDependencies.achievementManager ?? AppDependencies().achievementManager
    }
    
    var localizationManager: LocalizationManager {
        // Cast to LocalizationManager for backward compatibility
        if let manager = _dependencies?.baseDependencies.localizationProvider as? LocalizationManager {
            return manager
        }
        return AppDependencies().localizationProvider as? LocalizationManager ?? LocalizationManager()
    }
    
    var enhancedRemoteQuestionsService: EnhancedRemoteQuestionsService {
        _dependencies?.enhancedRemoteQuestionsService ?? EnhancedDependencies(baseDependencies: AppDependencies()).enhancedRemoteQuestionsService
    }
    
    var quizUseCase: QuizUseCaseProtocol {
        _dependencies?.baseDependencies.quizUseCase ?? AppDependencies().quizUseCase
    }
    
    var enhancedQuizUseCase: EnhancedQuizUseCaseProtocol {
        _dependencies?.enhancedQuizUseCase ?? EnhancedDependencies(baseDependencies: AppDependencies()).enhancedQuizUseCase
    }
    
    var examUseCase: ExamUseCaseProtocol {
        _dependencies?.baseDependencies.examUseCase ?? AppDependencies().examUseCase
    }
    
    var questionsRepository: QuestionsRepositoryProtocol {
        _dependencies?.baseDependencies.questionsRepository ?? AppDependencies().questionsRepository
    }
    
    var enhancedQuestionsRepository: EnhancedQuestionsRepositoryProtocol {
        _dependencies?.enhancedQuestionsRepository ?? EnhancedDependencies(baseDependencies: AppDependencies()).enhancedQuestionsRepository
    }
    
    var hapticManager: HapticManager {
        _dependencies?.baseDependencies.hapticManager ?? AppDependencies().hapticManager
    }
    
    var soundManager: SoundManager {
        _dependencies?.baseDependencies.soundManager ?? AppDependencies().soundManager
    }
    
    var notificationManager: NotificationManager {
        _dependencies?.baseDependencies.notificationManager ?? AppDependencies().notificationManager
    }
    
    // MARK: - Configuration Methods
    func configureNetwork(
        timeout: TimeInterval? = nil,
        maxRetries: Int? = nil,
        retryDelay: TimeInterval? = nil
    ) {
        guard var deps = _dependencies else {
            // Create new dependencies if not set
            let baseDeps = AppDependencies()
            _dependencies = EnhancedDependencies(baseDependencies: baseDeps)
            configureNetwork(timeout: timeout, maxRetries: maxRetries, retryDelay: retryDelay)
            return
        }
        
        let config = NetworkConfiguration(
            timeout: timeout ?? deps.networkConfiguration.timeout,
            maxRetries: maxRetries ?? deps.networkConfiguration.maxRetries,
            retryDelay: retryDelay ?? deps.networkConfiguration.retryDelay,
            maxRetryDelay: deps.networkConfiguration.maxRetryDelay
        )
        
        deps.networkConfiguration = config
        deps.networkManager = NetworkManager(configuration: config)
        _dependencies = deps
    }
    
    func configureCache(
        ttl: TimeInterval? = nil,
        maxCacheSize: Int? = nil,
        compressionEnabled: Bool? = nil
    ) {
        guard var deps = _dependencies else {
            // Create new dependencies if not set
            let baseDeps = AppDependencies()
            _dependencies = EnhancedDependencies(baseDependencies: baseDeps)
            configureCache(ttl: ttl, maxCacheSize: maxCacheSize, compressionEnabled: compressionEnabled)
            return
        }
        
        let config = CacheConfiguration(
            ttl: ttl ?? deps.cacheConfiguration.ttl,
            maxCacheSize: maxCacheSize ?? deps.cacheConfiguration.maxCacheSize,
            compressionEnabled: compressionEnabled ?? deps.cacheConfiguration.compressionEnabled
        )
        
        deps.cacheConfiguration = config
        deps.cacheManager = CacheManager(configuration: config)
        _dependencies = deps
    }
    
    // MARK: - Reset (Deprecated)
    @available(*, deprecated, message: "Create new EnhancedDependencies instead")
    func reset() {
        let baseDeps = AppDependencies()
        _dependencies = EnhancedDependencies(baseDependencies: baseDeps)
    }
}

// MARK: - Enhanced Dependencies
struct EnhancedDependencies {
    let baseDependencies: AppDependenciesProtocol
    
    var networkManager: NetworkManager
    var networkConfiguration: NetworkConfiguration
    var cacheManager: CacheManager
    var cacheConfiguration: CacheConfiguration
    var enhancedRemoteQuestionsService: EnhancedRemoteQuestionsService
    var enhancedQuestionsRepository: EnhancedQuestionsRepositoryProtocol
    var enhancedQuizUseCase: EnhancedQuizUseCaseProtocol
    
    init(baseDependencies: AppDependenciesProtocol) {
        self.baseDependencies = baseDependencies
        
        // Initialize enhanced services
        self.networkConfiguration = NetworkConfiguration.default
        self.networkManager = NetworkManager(configuration: networkConfiguration)
        
        self.cacheConfiguration = CacheConfiguration.default
        self.cacheManager = CacheManager(configuration: cacheConfiguration)
        
        self.enhancedRemoteQuestionsService = EnhancedRemoteQuestionsService(
            networkManager: networkManager,
            cacheManager: cacheManager,
            configuration: cacheConfiguration
        )
        
        self.enhancedQuestionsRepository = EnhancedQuestionsRepository(
            remoteService: enhancedRemoteQuestionsService,
            useRemoteQuestions: true,
            networkManager: networkManager
        )
        
        self.enhancedQuizUseCase = EnhancedQuizUseCase(
            questionsRepository: enhancedQuestionsRepository,
            networkManager: networkManager,
            adaptiveEngine: baseDependencies.adaptiveLearningEngine,
            profileManager: baseDependencies.profileManager,
            questionPoolProgressManager: baseDependencies.questionPoolProgressManager
        )
    }
    
    // MARK: - Configuration Methods
    func withNetworkConfiguration(
        timeout: TimeInterval? = nil,
        maxRetries: Int? = nil,
        retryDelay: TimeInterval? = nil
    ) -> EnhancedDependencies {
        let config = NetworkConfiguration(
            timeout: timeout ?? networkConfiguration.timeout,
            maxRetries: maxRetries ?? networkConfiguration.maxRetries,
            retryDelay: retryDelay ?? networkConfiguration.retryDelay,
            maxRetryDelay: networkConfiguration.maxRetryDelay
        )
        
        var updated = self
        updated.networkConfiguration = config
        updated.networkManager = NetworkManager(configuration: config)
        
        // Recreate dependent services with new network manager
        updated.enhancedRemoteQuestionsService = EnhancedRemoteQuestionsService(
            networkManager: updated.networkManager,
            cacheManager: updated.cacheManager,
            configuration: updated.cacheConfiguration
        )
        
        updated.enhancedQuestionsRepository = EnhancedQuestionsRepository(
            remoteService: updated.enhancedRemoteQuestionsService,
            useRemoteQuestions: true,
            networkManager: updated.networkManager
        )
        
        updated.enhancedQuizUseCase = EnhancedQuizUseCase(
            questionsRepository: updated.enhancedQuestionsRepository,
            networkManager: updated.networkManager,
            adaptiveEngine: baseDependencies.adaptiveLearningEngine,
            profileManager: baseDependencies.profileManager,
            questionPoolProgressManager: baseDependencies.questionPoolProgressManager
        )
        
        return updated
    }
    
    func withCacheConfiguration(
        ttl: TimeInterval? = nil,
        maxCacheSize: Int? = nil,
        compressionEnabled: Bool? = nil
    ) -> EnhancedDependencies {
        let config = CacheConfiguration(
            ttl: ttl ?? cacheConfiguration.ttl,
            maxCacheSize: maxCacheSize ?? cacheConfiguration.maxCacheSize,
            compressionEnabled: compressionEnabled ?? cacheConfiguration.compressionEnabled
        )
        
        var updated = self
        updated.cacheConfiguration = config
        updated.cacheManager = CacheManager(configuration: config)
        
        // Recreate dependent services with new cache manager
        updated.enhancedRemoteQuestionsService = EnhancedRemoteQuestionsService(
            networkManager: updated.networkManager,
            cacheManager: updated.cacheManager,
            configuration: updated.cacheConfiguration
        )
        
        updated.enhancedQuestionsRepository = EnhancedQuestionsRepository(
            remoteService: updated.enhancedRemoteQuestionsService,
            useRemoteQuestions: true,
            networkManager: updated.networkManager
        )
        
        updated.enhancedQuizUseCase = EnhancedQuizUseCase(
            questionsRepository: updated.enhancedQuestionsRepository,
            networkManager: updated.networkManager,
            adaptiveEngine: baseDependencies.adaptiveLearningEngine,
            profileManager: baseDependencies.profileManager,
            questionPoolProgressManager: baseDependencies.questionPoolProgressManager
        )
        
        return updated
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
