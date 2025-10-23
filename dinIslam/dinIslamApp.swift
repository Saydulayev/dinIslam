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
