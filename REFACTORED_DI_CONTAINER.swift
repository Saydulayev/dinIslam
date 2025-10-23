//
//  RefactoredDIContainer.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

// MARK: - Unified Dependency Injection Container
class RefactoredDIContainer {
    static let shared = RefactoredDIContainer()
    
    // MARK: - Core Services
    lazy var settingsManager: SettingsManagerProtocol = {
        SettingsManager()
    }()
    
    lazy var statsManager: StatsManagerProtocol = {
        StatsManager()
    }()
    
    lazy var achievementManager: AchievementManagerProtocol = {
        AchievementManager()
    }()
    
    lazy var localizationManager: LocalizationManager = {
        LocalizationManager.shared
    }()
    
    // MARK: - Network Layer
    lazy var networkManager: NetworkManagerProtocol = {
        NetworkManager()
    }()
    
    lazy var networkConfiguration: NetworkConfiguration = {
        NetworkConfiguration.default
    }()
    
    // MARK: - Cache Layer
    lazy var cacheManager: CacheManagerProtocol = {
        CacheManager()
    }()
    
    lazy var cacheConfiguration: CacheConfiguration = {
        CacheConfiguration.default
    }()
    
    // MARK: - Enhanced Services
    lazy var enhancedRemoteQuestionsService: EnhancedRemoteQuestionsService = {
        EnhancedRemoteQuestionsService(
            networkManager: networkManager as! NetworkManager,
            cacheManager: cacheManager as! CacheManager,
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
            networkManager: networkManager as! NetworkManager
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
            networkManager: networkManager as! NetworkManager
        )
    }()
    
    // MARK: - Managers
    lazy var hapticManager: HapticManagerProtocol = {
        HapticManager(settingsManager: settingsManager as! SettingsManager)
    }()
    
    lazy var soundManager: SoundManagerProtocol = {
        SoundManager(settingsManager: settingsManager as! SettingsManager)
    }()
    
    lazy var notificationManager: NotificationManagerProtocol = {
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
            questionsRepository = QuestionsRepository()
            quizUseCase = QuizUseCase(questionsRepository: questionsRepository)
            enhancedQuizUseCase = EnhancedQuizUseCase(
                questionsRepository: EnhancedQuestionsRepository(),
                networkManager: networkManager as! NetworkManager
            )
            enhancedQuestionsRepository = EnhancedQuestionsRepository()
            hapticManager = HapticManager(settingsManager: settingsManager as! SettingsManager)
            soundManager = SoundManager(settingsManager: settingsManager as! SettingsManager)
            notificationManager = NotificationManager()
        }
    }
}
