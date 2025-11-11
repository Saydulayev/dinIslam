//
//  AppSettings.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Observation
import SwiftUI

struct AppSettings: Codable {
    var language: AppLanguage
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var notificationsEnabled: Bool
    var theme: AppTheme
    
    enum CodingKeys: String, CodingKey {
        case language
        case soundEnabled
        case hapticEnabled
        case notificationsEnabled
        case theme
    }
    
    init() {
        self.language = .system
        self.soundEnabled = true
        self.hapticEnabled = true
        self.notificationsEnabled = true
        self.theme = .system
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        language = try container.decode(AppLanguage.self, forKey: .language)
        soundEnabled = try container.decode(Bool.self, forKey: .soundEnabled)
        hapticEnabled = try container.decode(Bool.self, forKey: .hapticEnabled)
        notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        // Обработка обратной совместимости - если theme отсутствует, используем .system
        theme = try container.decodeIfPresent(AppTheme.self, forKey: .theme) ?? .system
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system:
            return LocalizationManager.shared.localizedString(for: "settings.theme.system")
        case .light:
            return LocalizationManager.shared.localizedString(for: "settings.theme.light")
        case .dark:
            return LocalizationManager.shared.localizedString(for: "settings.theme.dark")
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
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
@MainActor
@Observable
final class SettingsManager {
    var settings: AppSettings
    
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let settingsKey = "AppSettings"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.settings = Self.loadSettings(from: userDefaults, key: settingsKey)
        applyLanguageSettings()
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
    
    func updateTheme(_ theme: AppTheme) {
        settings.theme = theme
        saveSettings()
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    private static func loadSettings(from userDefaults: UserDefaults, key: String) -> AppSettings {
        guard let data = userDefaults.data(forKey: key),
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
    }
}
