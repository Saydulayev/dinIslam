//
//  EnhancedQuestionsRepository.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Combine
import OSLog

// MARK: - Enhanced Questions Repository Protocol
protocol EnhancedQuestionsRepositoryProtocol {
    func loadQuestions(language: String) async throws -> [Question]
    func preloadQuestions(for languages: [String]) async
    func clearCache() async
    func getCacheStatus() -> CacheStatus
}

// MARK: - Cache Status
struct CacheStatus {
    let hasCachedData: Bool
    let lastUpdate: Date?
    let cacheSize: Int64
    let isExpired: Bool
}

// MARK: - Enhanced Questions Repository
class EnhancedQuestionsRepository: EnhancedQuestionsRepositoryProtocol {
    private let bundle: Bundle
    private let remoteService: EnhancedRemoteQuestionsService
    private let useRemoteQuestions: Bool
    private let networkManager: NetworkManager
    
    init(
        bundle: Bundle = .main,
        remoteService: EnhancedRemoteQuestionsService = EnhancedRemoteQuestionsService(),
        useRemoteQuestions: Bool = true,
        networkManager: NetworkManager = NetworkManager()
    ) {
        self.bundle = bundle
        self.remoteService = remoteService
        self.useRemoteQuestions = useRemoteQuestions
        self.networkManager = networkManager
    }
    
    func loadQuestions(language: String) async throws -> [Question] {
        let appLanguage: AppLanguage = language == "en" ? .english : .russian
        
        // Check network connectivity
        guard networkManager.isConnected || !useRemoteQuestions else {
            AppLogger.info("No internet connection, falling back to local questions", category: AppLogger.network)
            return try loadLocalQuestions(language: language)
        }
        
        if useRemoteQuestions {
            // Try to load from remote with fallback strategy
            let remoteQuestions = await remoteService.fetchQuestions(for: appLanguage)
            if !remoteQuestions.isEmpty {
                return remoteQuestions
            }
        }
        
        // Fallback to local questions
        return try loadLocalQuestions(language: language)
    }
    
    func preloadQuestions(for languages: [String]) async {
        let uniqueLanguages = Array(Set(languages))
        guard !uniqueLanguages.isEmpty else {
            return
        }
        
        AppLogger.info("Preloading questions for languages: \(uniqueLanguages)", category: AppLogger.data)
        
        for language in uniqueLanguages {
            let appLanguage: AppLanguage = language == "en" ? .english : .russian
            _ = await remoteService.fetchQuestions(for: appLanguage, manageLoadingState: false)
            AppLogger.info("Preloaded questions for \(language)", category: AppLogger.data)
        }
    }
    
    func clearCache() async {
        remoteService.clearCache()
        AppLogger.info("Questions cache cleared", category: AppLogger.data)
    }
    
    func getCacheStatus() -> CacheStatus {
        let cacheInfo = remoteService.getCacheInfo()
        let hasCachedData = cacheInfo.entries > 0
        let lastUpdate = remoteService.lastUpdateDate
        let cacheSize = cacheInfo.size
        
        // Check if cache is expired (simplified check)
        let isExpired = lastUpdate?.timeIntervalSinceNow ?? 0 < -24 * 60 * 60 // 24 hours
        
        return CacheStatus(
            hasCachedData: hasCachedData,
            lastUpdate: lastUpdate,
            cacheSize: cacheSize,
            isExpired: isExpired
        )
    }
    
    private func loadLocalQuestions(language: String) throws -> [Question] {
        let fileName = language == "en" ? "questions_en" : "questions"
        
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw EnhancedQuestionsError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let questions = try JSONDecoder().decode([Question].self, from: data)
        
        guard !questions.isEmpty else {
            throw EnhancedQuestionsError.emptyData
        }
        
        return questions
    }
}

// MARK: - Enhanced Questions Error
enum EnhancedQuestionsError: LocalizedError {
    case fileNotFound
    case emptyData
    case decodingError
    case networkUnavailable
    case cacheError
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return NSLocalizedString("error.fileNotFound", comment: "Questions file not found")
        case .emptyData:
            return NSLocalizedString("error.emptyData", comment: "No questions found")
        case .decodingError:
            return NSLocalizedString("error.decodingError", comment: "Failed to decode questions")
        case .networkUnavailable:
            return NSLocalizedString("error.networkUnavailable", comment: "Network unavailable")
        case .cacheError:
            return NSLocalizedString("error.cacheError", comment: "Cache error")
        case .timeout:
            return NSLocalizedString("error.timeout", comment: "Request timeout")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound, .emptyData, .decodingError:
            return NSLocalizedString("error.recoverySuggestion.reload", comment: "Try reloading the app")
        case .networkUnavailable:
            return NSLocalizedString("error.recoverySuggestion.checkConnection", comment: "Check your internet connection")
        case .cacheError:
            return NSLocalizedString("error.recoverySuggestion.clearCache", comment: "Try clearing the cache")
        case .timeout:
            return NSLocalizedString("error.recoverySuggestion.retry", comment: "Try again")
        }
    }
}
