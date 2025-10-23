//
//  Constants.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

// MARK: - App Constants
struct AppConstants {
    // MARK: - Timing
    struct Timing {
        static let answerDisplayDelay: TimeInterval = 1.5
        static let networkTimeout: TimeInterval = 30.0
        static let retryDelay: TimeInterval = 1.0
        static let maxRetryDelay: TimeInterval = 10.0
    }
    
    // MARK: - Quiz
    struct Quiz {
        static let questionsPerSession = 20
        static let newRecordThreshold = 0.8 // 80%
        static let maxRetries = 3
    }
    
    // MARK: - Cache
    struct Cache {
        static let ttl: TimeInterval = 24 * 60 * 60 // 24 hours
        static let maxCacheSize = 100 * 1024 * 1024 // 100MB
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let appSettings = "AppSettings"
        static let userStats = "UserStats"
        static let bestScore = "bestScore"
    }
    
    // MARK: - File Names
    struct FileNames {
        static let questionsRu = "questions"
        static let questionsEn = "questions_en"
        static let questionsExtension = "json"
    }
    
    // MARK: - System Sounds
    struct SystemSounds {
        static let success = 1103
        static let error = 1104
        static let selection = 1105
    }
}
