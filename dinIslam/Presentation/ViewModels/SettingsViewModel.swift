//
//  SettingsViewModel.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Observation
import UIKit
import AudioToolbox

@Observable
class SettingsViewModel {
    private let settingsManager: SettingsManager
    private let hapticManager: HapticManager
    private let soundManager: SoundManager
    private let localizationProvider: LocalizationProviding
    private let achievementManager: AchievementManaging
    
    // Убираем дублирование - используем только settingsManager.settings
    var settings: AppSettings {
        settingsManager.settings
    }
    
    var showingLanguagePicker = false
    var showingPrivacyPolicy = false
    var showingTermsOfService = false
    var refreshTrigger = UUID()
    /// Адрес, письмо на который не удалось открыть (нет настроенной почты)
    var unavailableMailRecipient: FeedbackRecipient?
    
    enum FeedbackRecipient {
        case technical
        case religious
        
        var address: String {
            switch self {
            case .technical: return "saydulayev.wien@gmail.com"
            case .religious: return "amigomuslim65@gmail.com"
            }
        }
        
        var mailURL: URL? {
            let subjectKey: String
            switch self {
            case .technical: subjectKey = "settings.feedback.technical.subject"
            case .religious: subjectKey = "settings.feedback.religious.subject"
            }
            var components = URLComponents()
            components.scheme = "mailto"
            components.path = address
            components.queryItems = [URLQueryItem(name: "subject", value: subjectKey.localized)]
            return components.url
        }
    }
    
    init(
        settingsManager: SettingsManager,
        localizationProvider: LocalizationProviding? = nil,
        achievementManager: AchievementManaging? = nil
    ) {
        self.settingsManager = settingsManager
        self.hapticManager = HapticManager(settingsManager: settingsManager)
        self.soundManager = SoundManager(settingsManager: settingsManager)
        // Use provided dependencies or create defaults for backward compatibility
        self.localizationProvider = localizationProvider ?? LocalizationManager()
        self.achievementManager = achievementManager ?? AchievementManager(notificationManager: NotificationManager())
    }
    
    // MARK: - Language Settings
    func updateLanguage(_ language: AppLanguage) {
        settingsManager.updateLanguage(language)
        localizationProvider.setLanguage(language.languageCode)
        refreshTrigger = UUID()
        hapticManager.selectionChanged()
        achievementManager.refreshLocalization()
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
    
    /// Системный запрос оценки может не показаться (лимит Apple, TestFlight),
    /// поэтому кнопка открывает форму отзыва в App Store
    let writeReviewURL = URL(string: "https://apps.apple.com/app/id6754708587?action=write-review")
    
    // MARK: - About Actions
    func openAppStore() {
        hapticManager.selectionChanged()
        
        if let url = URL(string: "https://apps.apple.com/app/id6754708587") {
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
        
        guard let shareURL = URL(string: "https://apps.apple.com/app/id6754708587") else {
            AppLogger.warning("Share URL is invalid, skipping share sheet", category: AppLogger.ui)
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [
                NSLocalizedString("settings.share.text", comment: "Share text"),
                shareURL
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
        achievementManager.refreshLocalization()
    }
}
