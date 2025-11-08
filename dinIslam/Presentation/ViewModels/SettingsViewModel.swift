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
import AudioToolbox

@Observable
class SettingsViewModel {
    private let settingsManager: SettingsManager
    private let hapticManager: HapticManager
    private let soundManager: SoundManager
    
    // Убираем дублирование - используем только settingsManager.settings
    var settings: AppSettings {
        settingsManager.settings
    }
    
    var showingLanguagePicker = false
    var showingPrivacyPolicy = false
    var showingTermsOfService = false
    var refreshTrigger = UUID()
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self.hapticManager = HapticManager(settingsManager: settingsManager)
        self.soundManager = SoundManager(settingsManager: settingsManager)
    }
    
    // MARK: - Language Settings
    func updateLanguage(_ language: AppLanguage) {
        settingsManager.updateLanguage(language)
        
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
        AchievementManager.shared.refreshLocalization()
    }
    
    // MARK: - Sound Settings
    func updateSoundEnabled(_ enabled: Bool) {
        settingsManager.updateSoundEnabled(enabled)
        hapticManager.selectionChanged()
        
        // Play sound to demonstrate the setting
        if enabled {
            soundManager.playSuccessSound()
        }
    }
    
    // MARK: - Haptic Settings
    func updateHapticEnabled(_ enabled: Bool) {
        settingsManager.updateHapticEnabled(enabled)
        if enabled {
            hapticManager.selectionChanged()
        }
    }
    
    // MARK: - Notifications Settings
    func updateNotificationsEnabled(_ enabled: Bool) {
        settingsManager.updateNotificationsEnabled(enabled)
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
        showingPrivacyPolicy = true
    }
    
    func openTermsOfService() {
        hapticManager.selectionChanged()
        showingTermsOfService = true
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
        AchievementManager.shared.refreshLocalization()
    }
}
