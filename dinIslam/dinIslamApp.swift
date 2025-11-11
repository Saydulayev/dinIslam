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

private struct SettingsManagerKey: EnvironmentKey {
    static let defaultValue = SettingsManager()
}

private struct ProfileManagerKey: EnvironmentKey {
    static let defaultValue = ProfileManager(
        statsManager: StatsManager(),
        examStatisticsManager: ExamStatisticsManager()
    )
}

extension EnvironmentValues {
    var statsManager: StatsManager {
        get { self[StatsManagerKey.self] }
        set { self[StatsManagerKey.self] = newValue }
    }

    var settingsManager: SettingsManager {
        get { self[SettingsManagerKey.self] }
        set { self[SettingsManagerKey.self] = newValue }
    }

    var profileManager: ProfileManager {
        get { self[ProfileManagerKey.self] }
        set { self[ProfileManagerKey.self] = newValue }
    }
}

@main
struct dinIslamApp: App {
    private let container = DIContainer.shared
    private let enhancedContainer = EnhancedDIContainer.shared
    @State private var colorScheme: ColorScheme?
    
    init() {
        // Настройка улучшенной сетевой архитектуры
        configureEnhancedNetworking()
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
                settingsManager: container.settingsManager,
                profileManager: container.profileManager,
                examUseCase: container.examUseCase,
                examStatisticsManager: container.examStatisticsManager
            )
            .environment(\.settingsManager, container.settingsManager)
            .environmentObject(container.achievementManager)
            .environmentObject(container.remoteQuestionsService)
            .environmentObject(container.notificationManager)
            .environment(\.statsManager, container.statsManager)
            .environment(\.profileManager, container.profileManager)
            .preferredColorScheme(colorScheme)
            .onAppear {
                updateColorScheme()
            }
            .onChange(of: container.settingsManager.settings.theme) { _, _ in
                updateColorScheme()
            }
        }
    }
    
    private func updateColorScheme() {
        colorScheme = container.settingsManager.settings.theme.colorScheme
    }
}
