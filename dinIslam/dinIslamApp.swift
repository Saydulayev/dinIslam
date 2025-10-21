//
//  dinIslamApp.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

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
        }
    }
}
