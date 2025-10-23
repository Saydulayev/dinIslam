//
//  EnhancedLocalizationManager.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Enhanced Localization Manager with Pluralization Support
@MainActor
class EnhancedLocalizationManager: ObservableObject {
    static let shared = EnhancedLocalizationManager()
    
    @Published var currentLanguage: String = "ru" // Default to Russian
    
    // MARK: - Caching
    private var cachedLocalizedStrings: [String: String] = [:]
    
    private init() {
        // Load saved language from UserDefaults
        if let savedLanguage = UserDefaults.standard.string(forKey: "SelectedLanguage") {
            currentLanguage = savedLanguage
        } else {
            // Use system language if available
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "ru"
            currentLanguage = ["ru", "en"].contains(systemLanguage) ? systemLanguage : "ru"
        }
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: "SelectedLanguage")
        
        // Clear cache when language changes
        cachedLocalizedStrings.removeAll()
        
        // Force UI update
        objectWillChange.send()
    }
    
    // MARK: - Basic Localization
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
    
    // MARK: - Pluralization Support
    func localizedString(for key: String, count: Int) -> String {
        let pluralKey = getPluralKey(for: key, count: count)
        return localizedString(for: pluralKey)
    }
    
    private func getPluralKey(for key: String, count: Int) -> String {
        switch currentLanguage {
        case "ru":
            return getRussianPluralKey(for: key, count: count)
        case "en":
            return getEnglishPluralKey(for: key, count: count)
        default:
            return getEnglishPluralKey(for: key, count: count)
        }
    }
    
    private func getRussianPluralKey(for key: String, count: Int) -> String {
        let absCount = abs(count)
        let lastDigit = absCount % 10
        let lastTwoDigits = absCount % 100
        
        // Russian pluralization rules
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "\(key)_5" // 11-19 use plural form
        } else if lastDigit == 1 {
            return key // 1, 21, 31, etc. use singular
        } else if lastDigit >= 2 && lastDigit <= 4 {
            return "\(key)_2" // 2-4, 22-24, etc. use few form
        } else {
            return "\(key)_5" // 0, 5-9, 10, 20, etc. use plural form
        }
    }
    
    private func getEnglishPluralKey(for key: String, count: Int) -> String {
        let absCount = abs(count)
        
        // English pluralization rules
        if absCount == 1 {
            return key // Singular
        } else {
            return "\(key)_other" // Plural
        }
    }
    
    // MARK: - Formatted Strings with Pluralization
    func localizedString(for key: String, count: Int, arguments: CVarArg...) -> String {
        let localizedTemplate = localizedString(for: key, count: count)
        return String(format: localizedTemplate, arguments: arguments)
    }
}

// MARK: - Enhanced String Extension
// Note: String extension methods are defined in LocalizationManager.swift to avoid conflicts

// MARK: - Enhanced Localized Text View
struct EnhancedLocalizedText: View {
    let key: String
    let count: Int?
    let arguments: [CVarArg]
    @ObservedObject private var localizationManager = EnhancedLocalizationManager.shared
    
    init(_ key: String, count: Int? = nil, arguments: CVarArg...) {
        self.key = key
        self.count = count
        self.arguments = arguments
    }
    
    var body: some View {
        if let count = count {
            if arguments.isEmpty {
                Text(localizationManager.localizedString(for: key, count: count))
            } else {
                Text(localizationManager.localizedString(for: key, count: count, arguments: arguments))
            }
        } else {
            Text(localizationManager.localizedString(for: key))
        }
    }
}

// MARK: - Accessibility Support
extension EnhancedLocalizationManager {
    func accessibilityLabel(for key: String, count: Int? = nil) -> String {
        if let count = count {
            return localizedString(for: key, count: count)
        } else {
            return localizedString(for: key)
        }
    }
    
    func accessibilityHint(for key: String) -> String {
        return localizedString(for: key)
    }
}
