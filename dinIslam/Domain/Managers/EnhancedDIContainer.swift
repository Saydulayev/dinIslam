//
//  EnhancedDIContainer.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

// MARK: - Enhanced Dependency Injection Container
class EnhancedDIContainer {
    static let shared = EnhancedDIContainer()
    
    // MARK: - Network Layer
    lazy var networkManager: NetworkManager = {
        NetworkManager()
    }()
    
    lazy var networkConfiguration: NetworkConfiguration = {
        NetworkConfiguration.default
    }()
    
    // MARK: - Cache Layer
    lazy var cacheManager: CacheManager = {
        CacheManager()
    }()
    
    lazy var cacheConfiguration: CacheConfiguration = {
        CacheConfiguration.default
    }()
    
    // MARK: - Core Services
    lazy var settingsManager: SettingsManager = {
        SettingsManager()
    }()
    
    lazy var statsManager: StatsManager = {
        DIContainer.shared.statsManager
    }()
    
    lazy var examStatisticsManager: ExamStatisticsManager = {
        DIContainer.shared.examStatisticsManager
    }()

    lazy var adaptiveLearningEngine: AdaptiveLearningEngine = {
        DIContainer.shared.adaptiveLearningEngine
    }()

    lazy var profileManager: ProfileManager = {
        DIContainer.shared.profileManager
    }()
    
    lazy var achievementManager: AchievementManager = {
        let manager = AchievementManager.shared
        manager.configureDependencies(notificationManager: notificationManager)
        return manager
    }()
    
    lazy var localizationManager: LocalizationManager = {
        LocalizationManager.shared
    }()
    
    // MARK: - Enhanced Services
    lazy var enhancedRemoteQuestionsService: EnhancedRemoteQuestionsService = {
        EnhancedRemoteQuestionsService(
            networkManager: networkManager,
            cacheManager: cacheManager,
            configuration: cacheConfiguration
        )
    }()
    
    // MARK: - Use Cases
    lazy var quizUseCase: QuizUseCaseProtocol = {
        QuizUseCase(
            questionsRepository: questionsRepository,
            adaptiveEngine: adaptiveLearningEngine,
            profileManager: profileManager
        )
    }()
    
    lazy var enhancedQuizUseCase: EnhancedQuizUseCaseProtocol = {
        EnhancedQuizUseCase(
            questionsRepository: enhancedQuestionsRepository,
            networkManager: networkManager,
            adaptiveEngine: adaptiveLearningEngine,
            profileManager: profileManager
        )
    }()
    
    lazy var examUseCase: ExamUseCaseProtocol = {
        ExamUseCase(questionsRepository: questionsRepository, examStatisticsManager: examStatisticsManager)
    }()
    
    // MARK: - Repositories
    lazy var questionsRepository: QuestionsRepositoryProtocol = {
        QuestionsRepository(
            remoteService: RemoteQuestionsService(),
            useRemoteQuestions: true
        )
    }()
    
    lazy var enhancedQuestionsRepository: EnhancedQuestionsRepositoryProtocol = {
        EnhancedQuestionsRepository(
            remoteService: enhancedRemoteQuestionsService,
            useRemoteQuestions: true,
            networkManager: networkManager
        )
    }()
    
    // MARK: - Managers
    lazy var hapticManager: HapticManager = {
        HapticManager(settingsManager: settingsManager)
    }()
    
    lazy var soundManager: SoundManager = {
        SoundManager(settingsManager: settingsManager)
    }()
    
    lazy var notificationManager: NotificationManager = {
        NotificationManager()
    }()
    
    private init() {}
    
    // MARK: - Configuration Methods
    func configureNetwork(
        timeout: TimeInterval? = nil,
        maxRetries: Int? = nil,
        retryDelay: TimeInterval? = nil
    ) {
        let config = NetworkConfiguration(
            timeout: timeout ?? networkConfiguration.timeout,
            maxRetries: maxRetries ?? networkConfiguration.maxRetries,
            retryDelay: retryDelay ?? networkConfiguration.retryDelay,
            maxRetryDelay: networkConfiguration.maxRetryDelay
        )
        
        networkConfiguration = config
        // Recreate network manager with new configuration
        networkManager = NetworkManager(configuration: config)
    }
    
    func configureCache(
        ttl: TimeInterval? = nil,
        maxCacheSize: Int? = nil,
        compressionEnabled: Bool? = nil
    ) {
        let config = CacheConfiguration(
            ttl: ttl ?? cacheConfiguration.ttl,
            maxCacheSize: maxCacheSize ?? cacheConfiguration.maxCacheSize,
            compressionEnabled: compressionEnabled ?? cacheConfiguration.compressionEnabled
        )
        
        cacheConfiguration = config
        // Recreate cache manager with new configuration
        cacheManager = CacheManager(configuration: config)
    }
    
    // MARK: - Reset
    func reset() {
        settingsManager = SettingsManager()
        statsManager = DIContainer.shared.statsManager
        examStatisticsManager = DIContainer.shared.examStatisticsManager
        achievementManager = AchievementManager.shared
        networkManager = NetworkManager()
        cacheManager = CacheManager()
        enhancedRemoteQuestionsService = EnhancedRemoteQuestionsService()
        // Fix: pass QuestionsRepositoryProtocol to QuizUseCase
        questionsRepository = QuestionsRepository()
        adaptiveLearningEngine = DIContainer.shared.adaptiveLearningEngine
        profileManager = DIContainer.shared.profileManager
        quizUseCase = QuizUseCase(
            questionsRepository: questionsRepository,
            adaptiveEngine: adaptiveLearningEngine,
            profileManager: profileManager
        )
        enhancedQuizUseCase = EnhancedQuizUseCase(
            questionsRepository: EnhancedQuestionsRepository(),
            networkManager: networkManager,
            adaptiveEngine: adaptiveLearningEngine,
            profileManager: profileManager
        )
        enhancedQuestionsRepository = EnhancedQuestionsRepository()
        hapticManager = HapticManager(settingsManager: settingsManager)
        soundManager = SoundManager(settingsManager: settingsManager)
        notificationManager = NotificationManager()
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
}

// MARK: - Enhanced Quiz Use Case
class EnhancedQuizUseCase: EnhancedQuizUseCaseProtocol {
    private let questionsRepository: EnhancedQuestionsRepositoryProtocol
    private let networkManager: NetworkManager
    private let adaptiveEngine: AdaptiveLearningEngine
    private let profileManager: ProfileManager
    private let questionPoolVersion = 1
    
    init(
        questionsRepository: EnhancedQuestionsRepositoryProtocol,
        networkManager: NetworkManager,
        adaptiveEngine: AdaptiveLearningEngine,
        profileManager: ProfileManager
    ) {
        self.questionsRepository = questionsRepository
        self.networkManager = networkManager
        self.adaptiveEngine = adaptiveEngine
        self.profileManager = profileManager
    }
    
    func startQuiz(language: String) async throws -> [Question] {
        let allQuestions = try await questionsRepository.loadQuestions(language: language)
        let progress = QuestionPoolProgress(version: questionPoolVersion)
        let used = progress.usedIds
        
        let sessionCount = min(20, allQuestions.count)
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
        
        progress.markUsed(selected.map { $0.id })
        return selected
    }
    
    func shuffleAnswers(for question: Question) -> Question {
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
}
