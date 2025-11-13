//
//  LocalizationManager.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Localization Manager
@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
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
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    func localized(arguments: CVarArg...) -> String {
        let format = LocalizationManager.shared.localizedString(for: self)
        return String(format: format, arguments: arguments)
    }
    
    func localized(count: Int) -> String {
        return EnhancedLocalizationManager.shared.localizedString(for: self, count: count)
    }
    
    func localized(count: Int, arguments: CVarArg...) -> String {
        return EnhancedLocalizationManager.shared.localizedString(for: self, count: count, arguments: arguments)
    }
}

// MARK: - Localized Text View
struct LocalizedText: View {
    let key: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    init(_ key: String) {
        self.key = key
    }
    
    var body: some View {
        Text(localizationManager.localizedString(for: key))
    }
}
