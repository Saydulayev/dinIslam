//
//  DefaultStartLifecycleManager.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
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
        let newLanguageCode = languageCode(from: settingsManager)
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
        let newLanguageCode = languageCode(from: settingsManager)
        onLanguageCodeUpdate(newLanguageCode)
    }
    
    // MARK: - Private Helpers
    private func clearBadge() {
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: { _ in })
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    private func languageCode(from settingsManager: SettingsManager) -> String {
        settingsManager.settings.language.locale?.language.languageCode?.identifier ?? "ru"
    }
}

