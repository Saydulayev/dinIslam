//
//  dinIslamApp.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

@main
struct dinIslamApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var statsManager = StatsManager()
    
    var body: some Scene {
        WindowGroup {
            StartView(
                quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository()),
                statsManager: statsManager
            )
            .environmentObject(settingsManager)
        }
    }
}
