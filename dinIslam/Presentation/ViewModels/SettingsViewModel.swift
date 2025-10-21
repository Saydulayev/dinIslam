//
//  SettingsViewModel.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Observation
import UIKit
import StoreKit

@Observable
class SettingsViewModel {
    private let settingsManager: SettingsManager
    private let hapticManager: HapticManager
    
    var settings: AppSettings
    var showingLanguagePicker = false
    var refreshTrigger = UUID()
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self.settings = settingsManager.settings
        self.hapticManager = HapticManager(settingsManager: settingsManager)
    }
    
    // MARK: - Language Settings
    func updateLanguage(_ language: AppLanguage) {
        settingsManager.updateLanguage(language)
        settings = settingsManager.settings
        
        // Update localization helper
        let languageCode: String
        switch language {
        case .system:
            // Normalize preferred localization to base language code (e.g., "en-GB" -> "en")
            let preferred = Bundle.main.preferredLocalizations.first
            let normalized = preferred.flatMap { Locale(identifier: $0).language.languageCode?.identifier }
            languageCode = normalized ?? "en"
        case .russian:
            languageCode = "ru"
        case .english:
            languageCode = "en"
        }
        
        LocalizationManager.shared.setLanguage(languageCode)
        refreshTrigger = UUID()
        hapticManager.selectionChanged()
    }
    
    // MARK: - Sound Settings
    func updateSoundEnabled(_ enabled: Bool) {
        settingsManager.updateSoundEnabled(enabled)
        settings = settingsManager.settings
        hapticManager.selectionChanged()
    }
    
    // MARK: - Haptic Settings
    func updateHapticEnabled(_ enabled: Bool) {
        settingsManager.updateHapticEnabled(enabled)
        settings = settingsManager.settings
        if enabled {
            hapticManager.selectionChanged()
        }
    }
    
    // MARK: - Notifications Settings
    func updateNotificationsEnabled(_ enabled: Bool) {
        settingsManager.updateNotificationsEnabled(enabled)
        settings = settingsManager.settings
        hapticManager.selectionChanged()
    }
    
    
    
    func requestAppReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    // MARK: - About Actions
    func openAppStore() {
        hapticManager.selectionChanged()
        
        if let url = URL(string: "https://apps.apple.com/app/dinislam-quiz/id1234567890") {
            UIApplication.shared.open(url)
        }
    }
    
    func openPrivacyPolicy() {
        hapticManager.selectionChanged()
        
        if let url = URL(string: "https://example.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    func openTermsOfService() {
        hapticManager.selectionChanged()
        
        if let url = URL(string: "https://example.com/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    func shareApp() {
        hapticManager.selectionChanged()
        
        let activityViewController = UIActivityViewController(
            activityItems: [
                NSLocalizedString("settings.share.text", comment: "Share text"),
                URL(string: "https://apps.apple.com/app/dinislam-quiz/id1234567890")!
            ],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    // MARK: - Reset Settings
    func resetSettings() {
        hapticManager.selectionChanged()
        
        let defaultSettings = AppSettings()
        settingsManager.updateLanguage(defaultSettings.language)
        settingsManager.updateSoundEnabled(defaultSettings.soundEnabled)
        settingsManager.updateHapticEnabled(defaultSettings.hapticEnabled)
        settingsManager.updateNotificationsEnabled(defaultSettings.notificationsEnabled)
        
        settings = settingsManager.settings
    }
}
