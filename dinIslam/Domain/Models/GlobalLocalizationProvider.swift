//
//  GlobalLocalizationProvider.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

/// Global localization provider instance for use in enum properties and String extensions
/// This is set during app initialization in dinIslamApp
/// NOTE: This is a compromise solution for cases where dependency injection is not possible
/// (e.g., enum computed properties, String extension methods)
/// In production code, prefer using LocalizationProviding directly via dependency injection
enum GlobalLocalizationProvider {
    private static var _instance: LocalizationProviding?
    
    static var instance: LocalizationProviding {
        get {
            if let instance = _instance {
                return instance
            }
            // Fallback: create a new instance if not set
            // This should not happen in production, but provides backward compatibility
            return LocalizationManager()
        }
        set {
            _instance = newValue
        }
    }
    
    static func setInstance(_ provider: LocalizationProviding) {
        _instance = provider
    }
}

