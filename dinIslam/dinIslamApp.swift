//
//  dinIslamApp.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

// MARK: - Environment Keys
private struct StatsManagerKey: EnvironmentKey {
    static let defaultValue = StatsManager()
}

extension EnvironmentValues {
    var statsManager: StatsManager {
        get { self[StatsManagerKey.self] }
        set { self[StatsManagerKey.self] = newValue }
    }
}

@main
struct dinIslamApp: App {
    private let container = DIContainer.shared
    private let enhancedContainer = EnhancedDIContainer.shared
    
    init() {
        // Настройка улучшенной сетевой архитектуры
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            configureEnhancedNetworking()
        }
    }
    
    private func configureEnhancedNetworking() {
        // Настройка для production
        enhancedContainer.configureNetwork(
            timeout: 30.0,      // 30 секунд таймаут
            maxRetries: 3,      // 3 попытки
            retryDelay: 1.0     // 1 секунда между попытками
        )
        
        // Настройка кэша
        enhancedContainer.configureCache(
            ttl: 24 * 60 * 60,  // 24 часа TTL
            maxCacheSize: 100 * 1024 * 1024, // 100MB
            compressionEnabled: true
        )
    }
    
    var body: some Scene {
        WindowGroup {
            StartView(
                quizUseCase: container.quizUseCase,
                statsManager: container.statsManager,
                settingsManager: container.settingsManager
            )
            .environmentObject(container.settingsManager)
            .environmentObject(container.achievementManager)
            .environmentObject(container.remoteQuestionsService)
            .environmentObject(container.notificationManager)
            .environment(\.statsManager, container.statsManager)
        }
    }
}
