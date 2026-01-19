//
//  EnhancedRemoteQuestionsService.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Combine
import OSLog

// MARK: - Cache Configuration
struct CacheConfiguration {
    let ttl: TimeInterval
    let maxCacheSize: Int
    let compressionEnabled: Bool
    
    static let `default` = CacheConfiguration(
        ttl: 24 * 60 * 60, // 24 hours
        maxCacheSize: 100 * 1024 * 1024, // 100MB
        compressionEnabled: true
    )
}

// MARK: - Cache Manager
class CacheManager {
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let configuration: CacheConfiguration
    
    init(configuration: CacheConfiguration = .default) {
        self.configuration = configuration
        
        // Create cache directory
        let cachesPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesPath.appendingPathComponent("QuestionsCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func cacheData<T: Codable>(_ data: T, for key: String) {
        do {
            let encodedData = try JSONEncoder().encode(data)
            let cacheData = CacheData(
                data: encodedData,
                timestamp: Date(),
                ttl: configuration.ttl
            )
            
            let cacheFilePath = cacheDirectory.appendingPathComponent("\(key).cache")
            let cacheEncoded = try JSONEncoder().encode(cacheData)
            try cacheEncoded.write(to: cacheFilePath)
            
            AppLogger.info("Cached data for key: \(key)", category: AppLogger.data)
        } catch {
            AppLogger.error("Failed to cache data for key: \(key)", error: error, category: AppLogger.data)
        }
    }
    
    func getCachedData<T: Codable>(_ type: T.Type, for key: String) -> T? {
        return getCachedData(type, for: key, allowExpired: false)
    }
    
    func getCachedData<T: Codable>(_ type: T.Type, for key: String, allowExpired: Bool) -> T? {
        let cacheFilePath = cacheDirectory.appendingPathComponent("\(key).cache")
        
        guard fileManager.fileExists(atPath: cacheFilePath.path),
              let cacheEncoded = try? Data(contentsOf: cacheFilePath),
              let cacheData = try? JSONDecoder().decode(CacheData.self, from: cacheEncoded) else {
            return nil
        }
        
        // Check TTL
        let now = Date()
        if now.timeIntervalSince(cacheData.timestamp) > cacheData.ttl {
            if allowExpired {
                AppLogger.warning("Using expired cache as backup for key: \(key)", category: AppLogger.data)
            } else {
                AppLogger.warning("Cache expired for key: \(key), but keeping as backup", category: AppLogger.data)
                return nil
            }
        }
        
        do {
            let decodedData = try JSONDecoder().decode(type, from: cacheData.data)
            return decodedData
        } catch {
            AppLogger.error("Failed to decode cached data for key: \(key)", error: error, category: AppLogger.data)
            return nil
        }
    }
    
    func invalidateCache(for key: String) {
        let cacheFilePath = cacheDirectory.appendingPathComponent("\(key).cache")
        try? fileManager.removeItem(at: cacheFilePath)
    }
    
    func clearAllCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func getCacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }
    
    func getCacheEntriesCount() -> Int {
        return (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil))?.count ?? 0
    }
}

// MARK: - Cache Data Model
private struct CacheData: Codable {
    let data: Data
    let timestamp: Date
    let ttl: TimeInterval
}

// MARK: - Enhanced Remote Questions Service
class EnhancedRemoteQuestionsService: ObservableObject {
    @Published var isLoading = false
    @Published var lastUpdateDate: Date?
    @Published var hasUpdates = false
    @Published var remoteQuestionsCount = 0
    @Published var cachedQuestionsCount = 0
    @Published var networkStatus: NetworkStatus = .unknown
    
    private let baseURL = "https://raw.githubusercontent.com/Saydulayev/dinIslam-questions/main"
    private let networkManager: NetworkManager
    private let cacheManager: CacheManager
    private let configuration: CacheConfiguration
    
    init(
        networkManager: NetworkManager = NetworkManager(),
        cacheManager: CacheManager = CacheManager(),
        configuration: CacheConfiguration = .default
    ) {
        self.networkManager = networkManager
        self.cacheManager = cacheManager
        self.configuration = configuration
        
        // Subscribe to network status changes
        networkManager.$isConnected
            .map { $0 ? NetworkStatus.connected : NetworkStatus.disconnected }
            .assign(to: &$networkStatus)
    }
    
    // MARK: - Public Methods
    
    func fetchQuestions(
        for language: AppLanguage,
        manageLoadingState: Bool = true
    ) async -> [Question] {
        if manageLoadingState {
            await MainActor.run {
                isLoading = true
            }
        }
        
        defer {
            if manageLoadingState {
                Task { @MainActor in
                    isLoading = false
                }
            }
        }
        
        let cacheKey = "questions_\(language.rawValue)"
        
        // Try to get from cache first
        if let cachedQuestions = cacheManager.getCachedData([Question].self, for: cacheKey) {
            AppLogger.info("Using cached questions for \(language.rawValue)", category: AppLogger.data)
            await MainActor.run {
                cachedQuestionsCount = cachedQuestions.count
            }
            return cachedQuestions
        }
        
        // Try to fetch from remote
        do {
            let remoteQuestions = try await loadFromRemote(language: language)
            
            // Cache the questions
            cacheManager.cacheData(remoteQuestions, for: cacheKey)
            
            // Update metadata
            await MainActor.run {
                lastUpdateDate = Date()
                remoteQuestionsCount = remoteQuestions.count
                cachedQuestionsCount = remoteQuestions.count
            }
            
            return remoteQuestions
            
        } catch {
            AppLogger.error("Failed to fetch remote questions", error: error, category: AppLogger.network)
            
            // Try to use expired cache as backup
            let cacheKey = "questions_\(language.rawValue)"
            if let expiredCacheQuestions = cacheManager.getCachedData([Question].self, for: cacheKey, allowExpired: true) {
                AppLogger.info("Using expired cache as backup for \(language.rawValue)", category: AppLogger.data)
                return expiredCacheQuestions
            }
            
            // Final fallback to local questions
            return loadLocalQuestions(for: language)
        }
    }
    
    func checkForUpdates(for language: AppLanguage) async {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let remoteQuestions = try await loadFromRemote(language: language)
            let cacheKey = "questions_\(language.rawValue)"
            let cachedQuestions = cacheManager.getCachedData([Question].self, for: cacheKey) ?? []
            
            await MainActor.run {
                remoteQuestionsCount = remoteQuestions.count
                cachedQuestionsCount = cachedQuestions.count
                hasUpdates = remoteQuestions.count > cachedQuestions.count
                
                AppLogger.info("Update check: Remote=\(remoteQuestions.count), Cached=\(cachedQuestions.count), HasUpdates=\(hasUpdates)", category: AppLogger.network)
            }
        } catch {
            AppLogger.error("Failed to check for updates", error: error, category: AppLogger.network)
            await MainActor.run {
                hasUpdates = false
            }
        }
    }
    
    func forceSync(for language: AppLanguage) async -> [Question] {
        AppLogger.info("Force sync started for \(language.rawValue)", category: AppLogger.network)
        
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            let remoteQuestions = try await loadFromRemote(language: language)
            let cacheKey = "questions_\(language.rawValue)"
            
            // Clear cache and cache new data
            cacheManager.invalidateCache(for: cacheKey)
            cacheManager.cacheData(remoteQuestions, for: cacheKey)
            
            await MainActor.run {
                lastUpdateDate = Date()
                hasUpdates = false
                cachedQuestionsCount = remoteQuestions.count
                remoteQuestionsCount = remoteQuestions.count
            }
            
            AppLogger.info("Force sync completed: \(remoteQuestions.count) questions", category: AppLogger.network)
            return remoteQuestions
            
        } catch {
            AppLogger.error("Force sync failed", error: error, category: AppLogger.network)
            return cacheManager.getCachedData([Question].self, for: "questions_\(language.rawValue)") ?? []
        }
    }
    
    func clearCache() {
        cacheManager.clearAllCache()
        AppLogger.info("Cache cleared", category: AppLogger.data)
    }
    
    func getCacheInfo() -> (size: Int64, entries: Int) {
        let size = cacheManager.getCacheSize()
        let entries = cacheManager.getCacheEntriesCount()
        return (size, entries)
    }
    
    // MARK: - Private Methods
    
    private func loadFromRemote(language: AppLanguage) async throws -> [Question] {
        let fileName = language == .russian ? "questions.json" : "questions_en.json"
        let urlString = "\(baseURL)/\(fileName)"
        
        AppLogger.info("EnhancedRemoteQuestionsService: Attempting to fetch from \(urlString)", category: AppLogger.network)
        
        // Используем RemoteQuestion из RemoteQuestionsService, который поддерживает оба формата
        let remoteQuestions = try await networkManager.request(
            url: urlString,
            responseType: [RemoteQuestion].self
        )
        
        AppLogger.info("EnhancedRemoteQuestionsService: Successfully loaded \(remoteQuestions.count) questions from \(fileName)", category: AppLogger.network)
        return remoteQuestions.map { $0.toQuestion() }
    }
    
    private func loadLocalQuestions(for language: AppLanguage) -> [Question] {
        let fileName = language == .russian ? "questions" : "questions_en"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let questions = try? JSONDecoder().decode([Question].self, from: data) else {
            AppLogger.error("Failed to load local questions for \(language.rawValue)", category: AppLogger.data)
            return []
        }
        
        AppLogger.info("Loaded \(questions.count) local questions for \(language.rawValue)", category: AppLogger.data)
        return questions
    }
}

// MARK: - Network Status
enum NetworkStatus {
    case connected
    case disconnected
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .connected:
            return "Connected"
        case .disconnected:
            return "No internet connection"
        case .unknown:
            return "Unknown"
        }
    }
}
