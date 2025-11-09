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
    
    lazy var examStatisticsManager: ExamStatisticsManager = {
        ExamStatisticsManager()
    }()
    
    lazy var achievementManager: AchievementManager = {
        let manager = AchievementManager.shared
        manager.configureDependencies(notificationManager: notificationManager)
        return manager
    }()
    
    lazy var localizationManager: LocalizationManager = {
        LocalizationManager.shared
    }()
    
    // MARK: - Use Cases
    lazy var quizUseCase: QuizUseCaseProtocol = {
        QuizUseCase(questionsRepository: questionsRepository)
    }()
    
    lazy var examUseCase: ExamUseCaseProtocol = {
        ExamUseCase(questionsRepository: questionsRepository, examStatisticsManager: examStatisticsManager)
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
    
    lazy var remoteQuestionsService: RemoteQuestionsService = {
        RemoteQuestionsService()
    }()
    
    lazy var notificationManager: NotificationManager = {
        NotificationManager()
    }()
    
    private init() {}
    
    // MARK: - Reset
    func reset() {
        // Reset all lazy properties by recreating the container
        // This is a simplified approach - in production вы можете использовать
        // более сложный DI-фреймворк
        settingsManager = SettingsManager()
        statsManager = StatsManager()
        achievementManager = AchievementManager.shared
        quizUseCase = QuizUseCase(questionsRepository: questionsRepository)
        questionsRepository = QuestionsRepository()
        hapticManager = HapticManager(settingsManager: settingsManager)
        soundManager = SoundManager(settingsManager: settingsManager)
        remoteQuestionsService = RemoteQuestionsService()
        notificationManager = NotificationManager()
    }
}
