//
//  DIContainer.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

// MARK: - Dependency Injection Container (Factory)
class DIContainer {
    // MARK: - Factory Methods
    static func createDependencies() -> AppDependencies {
        return AppDependencies()
    }
    
    // MARK: - Backward Compatibility (Deprecated - use createDependencies instead)
    @available(*, deprecated, message: "Use DIContainer.createDependencies() instead")
    static let shared: DIContainer = {
        let container = DIContainer()
        container._dependencies = AppDependencies()
        return container
    }()
    
    private var _dependencies: AppDependencies?
    
    private init() {}
    
    // MARK: - Lazy Properties for Backward Compatibility
    var settingsManager: SettingsManager {
        _dependencies?.settingsManager ?? AppDependencies().settingsManager
    }
    
    var statsManager: StatsManager {
        _dependencies?.statsManager ?? AppDependencies().statsManager
    }
    
    var examStatisticsManager: ExamStatisticsManager {
        _dependencies?.examStatisticsManager ?? AppDependencies().examStatisticsManager
    }

    var adaptiveLearningEngine: AdaptiveLearningEngine {
        _dependencies?.adaptiveLearningEngine ?? AppDependencies().adaptiveLearningEngine
    }

    var profileManager: ProfileManager {
        _dependencies?.profileManager ?? AppDependencies().profileManager
    }
    
    var achievementManager: AchievementManager {
        // Cast to AchievementManager for backward compatibility
        if let manager = _dependencies?.achievementManager as? AchievementManager {
            return manager
        }
        return AppDependencies().achievementManager as? AchievementManager ?? AchievementManager(notificationManager: NotificationManager())
    }
    
    var localizationManager: LocalizationManager {
        // Cast to LocalizationManager for backward compatibility
        if let manager = _dependencies?.localizationProvider as? LocalizationManager {
            return manager
        }
        return AppDependencies().localizationProvider as? LocalizationManager ?? LocalizationManager()
    }
    
    var quizUseCase: QuizUseCaseProtocol {
        _dependencies?.quizUseCase ?? AppDependencies().quizUseCase
    }
    
    var examUseCase: ExamUseCaseProtocol {
        _dependencies?.examUseCase ?? AppDependencies().examUseCase
    }
    
    var questionsRepository: QuestionsRepositoryProtocol {
        _dependencies?.questionsRepository ?? AppDependencies().questionsRepository
    }
    
    var hapticManager: HapticManager {
        _dependencies?.hapticManager ?? AppDependencies().hapticManager
    }
    
    var soundManager: SoundManager {
        _dependencies?.soundManager ?? AppDependencies().soundManager
    }
    
    var remoteQuestionsService: RemoteQuestionsService {
        _dependencies?.remoteQuestionsService ?? AppDependencies().remoteQuestionsService
    }
    
    var notificationManager: NotificationManager {
        _dependencies?.notificationManager ?? AppDependencies().notificationManager
    }
    
    // MARK: - Reset (Deprecated)
    @available(*, deprecated, message: "Create new AppDependencies instead")
    func reset() {
        _dependencies = AppDependencies()
    }
}
