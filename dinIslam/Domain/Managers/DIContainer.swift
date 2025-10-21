//
//  DIContainer.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

// MARK: - Dependency Injection Container
class DIContainer {
    static let shared = DIContainer()
    
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
    
    // MARK: - Use Cases
    lazy var quizUseCase: QuizUseCaseProtocol = {
        QuizUseCase(questionsRepository: questionsRepository)
    }()
    
    // MARK: - Repositories
    lazy var questionsRepository: QuestionsRepositoryProtocol = {
        QuestionsRepository()
    }()
    
    // MARK: - Managers
    lazy var hapticManager: HapticManager = {
        HapticManager(settingsManager: settingsManager)
    }()
    
    lazy var soundManager: SoundManager = {
        SoundManager(settingsManager: settingsManager)
    }()
    
    private init() {}
    
    // MARK: - Reset for Testing
    func reset() {
        // Reset all lazy properties for testing by recreating the container
        // This is a simplified approach - in production you might want to use
        // a more sophisticated dependency injection framework
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // Only reset during testing
            settingsManager = SettingsManager()
            statsManager = StatsManager()
            achievementManager = AchievementManager()
            quizUseCase = QuizUseCase(questionsRepository: questionsRepository)
            questionsRepository = QuestionsRepository()
            hapticManager = HapticManager(settingsManager: settingsManager)
            soundManager = SoundManager(settingsManager: settingsManager)
        }
    }
}
