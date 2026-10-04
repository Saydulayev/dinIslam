//
//  DefaultStartLifecycleManager.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation
import UserNotifications
import UIKit

final class DefaultStartLifecycleManager: StartLifecycleManaging {
    private let settingsManager: SettingsManager
    private let profileManager: ProfileManager
    private let questionsPreloading: QuestionsPreloading
    
    init(
        settingsManager: SettingsManager,
        profileManager: ProfileManager,
        questionsPreloading: QuestionsPreloading
    ) {
        self.settingsManager = settingsManager
        self.profileManager = profileManager
        self.questionsPreloading = questionsPreloading
    }
    
    func onAppear(
        onLanguageCodeUpdate: (String) -> Void,
        onProfileSync: @escaping () async -> Void
    ) {
        clearBadge()
        let newLanguageCode = settingsManager.settings.language.languageCode
        onLanguageCodeUpdate(newLanguageCode)
        
        Task {
            await questionsPreloading.preloadQuestions(for: ["ru", "en"])
        }
        
        if profileManager.isSignedIn {
            Task {
                await onProfileSync()
            }
        }
    }
    
    func onDisappear(cancelTask: () -> Void) {
        cancelTask()
    }
    
    func onLanguageChange(
        onLanguageCodeUpdate: (String) -> Void
    ) {
        let newLanguageCode = settingsManager.settings.language.languageCode
        onLanguageCodeUpdate(newLanguageCode)
    }
    
    // MARK: - Private Helpers
    private func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: { _ in })
    }
}

