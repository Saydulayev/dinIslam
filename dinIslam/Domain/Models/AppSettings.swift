//
//  AppSettings.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Combine

// MARK: - Language Change Notification
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

struct AppSettings: Codable {
    var language: AppLanguage
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var notificationsEnabled: Bool
    
    init() {
        self.language = .system
        self.soundEnabled = true
        self.hapticEnabled = true
        self.notificationsEnabled = true
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case system = "system"
    case russian = "ru"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .system:
            return LocalizationManager.shared.localizedString(for: "settings.language.system")
        case .russian:
            return LocalizationManager.shared.localizedString(for: "settings.language.russian")
        case .english:
            return LocalizationManager.shared.localizedString(for: "settings.language.english")
        }
    }
    
    var locale: Locale? {
        switch self {
        case .system:
            return nil
        case .russian:
            return Locale(identifier: "ru")
        case .english:
            return Locale(identifier: "en")
        }
    }
}

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    @Published var settings: AppSettings
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "AppSettings"
    
    init() {
        self.settings = Self.loadSettings()
    }
    
    func updateLanguage(_ language: AppLanguage) {
        settings.language = language
        saveSettings()
        applyLanguageSettings()
    }
    
    func updateSoundEnabled(_ enabled: Bool) {
        settings.soundEnabled = enabled
        saveSettings()
    }
    
    func updateHapticEnabled(_ enabled: Bool) {
        settings.hapticEnabled = enabled
        saveSettings()
    }
    
    func updateNotificationsEnabled(_ enabled: Bool) {
        settings.notificationsEnabled = enabled
        saveSettings()
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    private static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "AppSettings"),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
    
    private func applyLanguageSettings() {
        // Apply language settings to the app
        let languageCode: String
        
        switch settings.language {
        case .system:
            languageCode = Locale.current.language.languageCode?.identifier ?? "ru"
        case .russian:
            languageCode = "ru"
        case .english:
            languageCode = "en"
        }
        
        // Update localization manager
        LocalizationManager.shared.setLanguage(languageCode)
        
        // Force UI to update by posting notification
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
}
