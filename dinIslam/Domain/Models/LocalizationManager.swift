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
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = "ru" // Default to Russian
    
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
        
        // Force UI update
        objectWillChange.send()
    }
    
    func localizedString(for key: String) -> String {
        let bundle = Bundle.main
        
        // Try to get localized string from current language bundle
        if let path = bundle.path(forResource: currentLanguage, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            let localizedString = languageBundle.localizedString(forKey: key, value: nil, table: nil)
            if localizedString != key {
                return localizedString
            }
        }
        
        // Fallback to main bundle
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

// MARK: - Localized String Extension
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
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
