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
        StatsManager()
    }()
    
    lazy var achievementManager: AchievementManager = {
        AchievementManager()
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
        QuizUseCase(questionsRepository: questionsRepository)
    }()
    
    lazy var enhancedQuizUseCase: EnhancedQuizUseCaseProtocol = {
        EnhancedQuizUseCase(
            questionsRepository: enhancedQuestionsRepository,
            networkManager: networkManager
        )
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
    
    // MARK: - Reset for Testing
    func reset() {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // Only reset during testing
            settingsManager = SettingsManager()
            statsManager = StatsManager()
            achievementManager = AchievementManager()
            networkManager = NetworkManager()
            cacheManager = CacheManager()
            enhancedRemoteQuestionsService = EnhancedRemoteQuestionsService()
            // Fix: pass QuestionsRepositoryProtocol to QuizUseCase
            questionsRepository = QuestionsRepository()
            quizUseCase = QuizUseCase(questionsRepository: questionsRepository)
            enhancedQuizUseCase = EnhancedQuizUseCase(
                questionsRepository: EnhancedQuestionsRepository(),
                networkManager: networkManager
            )
            enhancedQuestionsRepository = EnhancedQuestionsRepository()
            hapticManager = HapticManager(settingsManager: settingsManager)
            soundManager = SoundManager(settingsManager: settingsManager)
            notificationManager = NotificationManager()
        }
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
    private let questionPoolVersion = 1
    
    init(
        questionsRepository: EnhancedQuestionsRepositoryProtocol,
        networkManager: NetworkManager
    ) {
        self.questionsRepository = questionsRepository
        self.networkManager = networkManager
    }
    
    func startQuiz(language: String) async throws -> [Question] {
        let allQuestions = try await questionsRepository.loadQuestions(language: language)
        let progress = QuestionPoolProgress(version: questionPoolVersion)
        let used = progress.usedIds
        let unusedQuestions = allQuestions.filter { !used.contains($0.id) }
        
        let sessionCount = min(20, allQuestions.count)
        var selected: [Question] = []
        
        if unusedQuestions.count >= sessionCount {
            selected = Array(unusedQuestions.shuffled().prefix(sessionCount))
            print("📚 Using \(selected.count) new questions")
        } else if unusedQuestions.count > 0 {
            selected = Array(unusedQuestions.shuffled())
            let remaining = sessionCount - unusedQuestions.count
            let repeatedQuestions = allQuestions.filter { used.contains($0.id) }
            let additional = Array(repeatedQuestions.shuffled().prefix(remaining))
            selected.append(contentsOf: additional)
            print("📚 Using \(unusedQuestions.count) new + \(additional.count) repeated questions")
        } else {
            progress.reset(for: questionPoolVersion)
            selected = Array(allQuestions.shuffled().prefix(sessionCount))
            print("🔄 All questions completed, starting fresh with \(selected.count) questions")
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
