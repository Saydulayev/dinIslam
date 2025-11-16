//
//  dinIslamApp.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

// MARK: - Environment Keys
private struct StatsManagerKey: EnvironmentKey {
    static let defaultValue: StatsManager? = nil
}

private struct SettingsManagerKey: EnvironmentKey {
    static let defaultValue: SettingsManager? = nil
}

private struct ProfileManagerKey: EnvironmentKey {
    static let defaultValue: ProfileManager? = nil
}

private struct LocalizationProviderKey: EnvironmentKey {
    static let defaultValue: LocalizationProviding? = nil
}

private struct AchievementManagerKey: EnvironmentKey {
    static let defaultValue: AchievementManaging? = nil
}

extension EnvironmentValues {
    var localizationProvider: LocalizationProviding {
        get { 
            self[LocalizationProviderKey.self] ?? LocalizationManager()
        }
        set { 
            self[LocalizationProviderKey.self] = newValue 
        }
    }
    
    var achievementManager: AchievementManaging {
        get { 
            self[AchievementManagerKey.self] ?? AchievementManager(
                notificationManager: NotificationManager()
            )
        }
        set { 
            self[AchievementManagerKey.self] = newValue 
        }
    }
}

extension EnvironmentValues {
    var statsManager: StatsManager {
        get { 
            self[StatsManagerKey.self] ?? StatsManager()
        }
        set { 
            self[StatsManagerKey.self] = newValue 
        }
    }

    var settingsManager: SettingsManager {
        get { 
            self[SettingsManagerKey.self] ?? SettingsManager()
        }
        set { 
            self[SettingsManagerKey.self] = newValue 
        }
    }

    var profileManager: ProfileManager {
        get { 
            self[ProfileManagerKey.self] ?? ProfileManager(
                statsManager: StatsManager(),
                examStatisticsManager: ExamStatisticsManager()
            )
        }
        set { 
            self[ProfileManagerKey.self] = newValue 
        }
    }
}

@main
struct dinIslamApp: App {
    private let dependencies: AppDependencies
    private let enhancedDependencies: EnhancedDependencies
    
    init() {
        // Create dependencies
        self.dependencies = DIContainer.createDependencies()
        
        // Set global localization provider for use in enum properties and String extensions
        GlobalLocalizationProvider.setInstance(dependencies.localizationProvider)
        
        // Create enhanced dependencies with production configuration
        var enhancedDeps = EnhancedDIContainer.createEnhancedDependencies(baseDependencies: dependencies)
        
        // Настройка улучшенной сетевой архитектуры
        enhancedDeps = enhancedDeps.withNetworkConfiguration(
            timeout: 30.0,      // 30 секунд таймаут
            maxRetries: 3,      // 3 попытки
            retryDelay: 1.0     // 1 секунда между попытками
        )
        
        enhancedDeps = enhancedDeps.withCacheConfiguration(
            ttl: 24 * 60 * 60,  // 24 часа TTL
            maxCacheSize: 100 * 1024 * 1024, // 100MB
            compressionEnabled: true
        )
        
        self.enhancedDependencies = enhancedDeps
    }
    
    var body: some Scene {
        WindowGroup {
            StartView(
                quizUseCase: dependencies.quizUseCase,
                statsManager: dependencies.statsManager,
                settingsManager: dependencies.settingsManager,
                profileManager: dependencies.profileManager,
                examUseCase: dependencies.examUseCase,
                examStatisticsManager: dependencies.examStatisticsManager,
                enhancedQuizUseCase: enhancedDependencies.enhancedQuizUseCase
            )
            .environment(\.settingsManager, dependencies.settingsManager)
            .environment(\.localizationProvider, dependencies.localizationProvider)
            .environment(\.achievementManager, dependencies.achievementManager)
            .environmentObject(dependencies.achievementManager as? AchievementManager ?? AchievementManager(notificationManager: dependencies.notificationManager))
            .environmentObject(dependencies.remoteQuestionsService)
            .environmentObject(dependencies.notificationManager)
            .environment(\.statsManager, dependencies.statsManager)
            .environment(\.profileManager, dependencies.profileManager)
            .preferredColorScheme(.dark)
        }
    }
}
