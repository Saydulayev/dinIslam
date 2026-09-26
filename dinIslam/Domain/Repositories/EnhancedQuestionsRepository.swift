//
//  EnhancedQuestionsRepository.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Combine
import OSLog

// MARK: - Questions Repository Protocol
protocol QuestionsRepositoryProtocol {
    func loadQuestions(language: String) async throws -> [Question]
}

// MARK: - Enhanced Questions Repository Protocol
protocol EnhancedQuestionsRepositoryProtocol: QuestionsRepositoryProtocol {
    func preloadQuestions(for languages: [String]) async
    func clearCache() async
    func getCacheStatus() -> CacheStatus
    
    // Update checking
    func checkForUpdates(language: String) async
    func hasUpdates() -> Bool
    func forceSync(language: String) async -> [Question]
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
        let isExpired = lastUpdate?.timeIntervalSinceNow ?? 0 < -CacheConfiguration.default.ttl
        
        return CacheStatus(
            hasCachedData: hasCachedData,
            lastUpdate: lastUpdate,
            cacheSize: cacheSize,
            isExpired: isExpired
        )
    }
    
    func checkForUpdates(language: String) async {
        let appLanguage: AppLanguage = language == "en" ? .english : .russian
        await remoteService.checkForUpdates(for: appLanguage)
    }
    
    func hasUpdates() -> Bool {
        return remoteService.hasUpdates
    }
    
    func forceSync(language: String) async -> [Question] {
        let appLanguage: AppLanguage = language == "en" ? .english : .russian
        return await remoteService.forceSync(for: appLanguage)
    }
    
    private func loadLocalQuestions(language: String) throws -> [Question] {
        let appLanguage: AppLanguage = language == "en" ? .english : .russian
        return try QuestionsFile.loadBundled(for: appLanguage, bundle: bundle)
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
            return "error.fileNotFound".localized
        case .emptyData:
            return "error.emptyData".localized
        case .decodingError:
            return "error.decodingError".localized
        case .networkUnavailable:
            return "error.networkUnavailable".localized
        case .cacheError:
            return "error.cacheError".localized
        case .timeout:
            return "error.timeout".localized
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound, .emptyData, .decodingError:
            return "error.recoverySuggestion.reload".localized
        case .networkUnavailable:
            return "error.recoverySuggestion.checkConnection".localized
        case .cacheError:
            return "error.recoverySuggestion.clearCache".localized
        case .timeout:
            return "error.recoverySuggestion.retry".localized
        }
    }
}
