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
    
    init() {
        // Initialize localization on app start
        let language = settingsManager.settings.language
        let languageCode: String
        switch language {
        case .system:
            languageCode = Locale.current.language.languageCode?.identifier ?? "ru"
        case .russian:
            languageCode = "ru"
        case .english:
            languageCode = "en"
        }
        LocalizationManager.shared.setLanguage(languageCode)
    }
    
    var body: some Scene {
        WindowGroup {
            StartView(viewModel: QuizViewModel(quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository())))
                .environmentObject(settingsManager)
        }
    }
}
