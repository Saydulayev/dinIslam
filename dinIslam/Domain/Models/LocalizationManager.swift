//
//  LocalizationManager.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Observation
import SwiftUI

// MARK: - Localization Manager
@MainActor
@Observable
class LocalizationManager: LocalizationProviding {
    var currentLanguage: String = "ru" // Default to Russian
    
    // MARK: - Caching
    // Кэш пополняется при чтении строк из body экранов: отслеживать его нельзя
    @ObservationIgnored private var cachedLocalizedStrings: [String: String] = [:]
    @ObservationIgnored private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        // Load saved language from UserDefaults
        if let savedLanguage = userDefaults.string(forKey: "SelectedLanguage") {
            currentLanguage = savedLanguage
        } else {
            currentLanguage = AppLanguage.system.languageCode
        }
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        userDefaults.set(language, forKey: "SelectedLanguage")
        
        // Clear cache when language changes
        cachedLocalizedStrings.removeAll()
    }
    
    func localizedString(for key: String) -> String {
        // Check cache first
        if let cachedString = cachedLocalizedStrings[key] {
            return cachedString
        }
        
        let bundle = Bundle.main
        var localizedString: String
        
        // Try to get localized string from current language bundle
        if let path = bundle.path(forResource: currentLanguage, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            localizedString = languageBundle.localizedString(forKey: key, value: nil, table: nil)
            if localizedString == key {
                // Fallback to main bundle
                localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)
            }
        } else {
            // Fallback to main bundle
            localizedString = bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        
        // Cache the result
        cachedLocalizedStrings[key] = localizedString
        
        return localizedString
    }
}

// MARK: - Localized String Extension
// NOTE: Using GlobalLocalizationProvider here for backward compatibility in String extension methods
// Extension methods cannot accept dependencies, so we use a global instance
// In production code, prefer using LocalizationProviding directly via dependency injection
extension String {
    var localized: String {
        let localizationProvider = GlobalLocalizationProvider.instance
        return localizationProvider.localizedString(for: self)
    }
    
    func localized(arguments: CVarArg...) -> String {
        let localizationProvider = GlobalLocalizationProvider.instance
        let format = localizationProvider.localizedString(for: self)
        return String(format: format, arguments: arguments)
    }
    
    func localized(count: Int) -> String {
        let localizationProvider = GlobalLocalizationProvider.instance
        let pluralKey = PluralRules.key(for: self, count: count, language: localizationProvider.currentLanguage)
        return localizationProvider.localizedString(for: pluralKey)
    }
    
    func localized(count: Int, arguments: CVarArg...) -> String {
        String(format: localized(count: count), arguments: arguments)
    }
}

// MARK: - Localized Dates
extension Date {
    /// Дата на языке приложения, а не системы
    func localizedFormatted(date: Date.FormatStyle.DateStyle, time: Date.FormatStyle.TimeStyle) -> String {
        let locale = Locale(identifier: GlobalLocalizationProvider.instance.currentLanguage)
        return formatted(Date.FormatStyle(date: date, time: time).locale(locale))
    }
}

// MARK: - Localized Text View
struct LocalizedText: View {
    let key: String
    @Environment(\.localizationProvider) private var localizationProvider
    
    init(_ key: String) {
        self.key = key
    }
    
    var body: some View {
        Text(localizationProvider.localizedString(for: key))
    }
}
