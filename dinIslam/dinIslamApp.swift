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
    
    var body: some Scene {
        WindowGroup {
            StartView(viewModel: QuizViewModel(quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository())))
                .environmentObject(settingsManager)
        }
    }
}
