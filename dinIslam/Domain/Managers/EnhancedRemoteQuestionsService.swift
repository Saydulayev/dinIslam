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
        ttl: 6 * 60 * 60, // 6 hours - shorter TTL for faster updates
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
    
    func cacheData<T: Codable>(_ data: T, for key: String, etag: String? = nil, lastModified: Date? = nil) {
        do {
            let encodedData = try JSONEncoder().encode(data)
            let cacheData = CacheData(
                data: encodedData,
                timestamp: Date(),
                ttl: configuration.ttl,
                etag: etag,
                lastModified: lastModified
            )
            
            let cacheFilePath = cacheDirectory.appendingPathComponent("\(key).cache")
            let cacheEncoded = try JSONEncoder().encode(cacheData)
            try cacheEncoded.write(to: cacheFilePath)
            
            AppLogger.info("Cached data for key: \(key) with ETag: \(etag ?? "none")", category: AppLogger.data)
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
    
    struct CachedDataWithMetadata<T: Codable> {
        let data: T
        let etag: String?
        let lastModified: Date?
        let timestamp: Date
        let isExpired: Bool
    }
    
    func getCachedDataWithMetadata<T: Codable>(_ type: T.Type, for key: String) -> CachedDataWithMetadata<T>? {
        let cacheFilePath = cacheDirectory.appendingPathComponent("\(key).cache")
        
        guard fileManager.fileExists(atPath: cacheFilePath.path),
              let cacheEncoded = try? Data(contentsOf: cacheFilePath),
              let cacheData = try? JSONDecoder().decode(CacheData.self, from: cacheEncoded) else {
            return nil
        }
        
        // Check TTL
        let now = Date()
        let isExpired = now.timeIntervalSince(cacheData.timestamp) > cacheData.ttl
        
        do {
            let decodedData = try JSONDecoder().decode(type, from: cacheData.data)
            return CachedDataWithMetadata(
                data: decodedData,
                etag: cacheData.etag,
                lastModified: cacheData.lastModified,
                timestamp: cacheData.timestamp,
                isExpired: isExpired
            )
        } catch {
            AppLogger.error("Failed to decode cached data with metadata for key: \(key)", error: error, category: AppLogger.data)
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
    let etag: String?
    let lastModified: Date?
    
    init(data: Data, timestamp: Date, ttl: TimeInterval, etag: String? = nil, lastModified: Date? = nil) {
        self.data = data
        self.timestamp = timestamp
        self.ttl = ttl
        self.etag = etag
        self.lastModified = lastModified
    }
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
        
        // Get cached data with metadata (including ETag)
        let cachedDataWithMetadata = cacheManager.getCachedDataWithMetadata([Question].self, for: cacheKey)
        
        // If we have valid (non-expired) cache, return it
        if let cached = cachedDataWithMetadata, !cached.isExpired {
            AppLogger.info("Using valid cached questions for \(language.rawValue)", category: AppLogger.data)
            await MainActor.run {
                cachedQuestionsCount = cached.data.count
            }
            return cached.data
        }
        
        // Try to fetch from remote with ETag
        do {
            let response = try await loadFromRemoteWithETag(
                language: language,
                cachedEtag: cachedDataWithMetadata?.etag,
                cachedData: cachedDataWithMetadata?.data
            )

            // Cache the data to refresh timestamp (revalidation) and persist new metadata when updated.
            cacheManager.cacheData(
                response.data,
                for: cacheKey,
                etag: response.etag ?? cachedDataWithMetadata?.etag,
                lastModified: response.lastModified ?? cachedDataWithMetadata?.lastModified
            )

            if response.notModified {
                AppLogger.info("Cache revalidated via 304 Not Modified for \(language.rawValue)", category: AppLogger.data)
            } else {
                AppLogger.info("Cached updated questions with ETag: \(response.etag ?? "none")", category: AppLogger.data)
            }
            
            // Update metadata
            await MainActor.run {
                lastUpdateDate = Date()
                remoteQuestionsCount = response.data.count
                cachedQuestionsCount = response.data.count
            }
            
            return response.data
            
        } catch {
            AppLogger.error("Failed to fetch remote questions", error: error, category: AppLogger.network)
            
            // Try to use expired cache as backup
            if let expired = cachedDataWithMetadata {
                AppLogger.warning("Using expired cache as backup for \(language.rawValue)", category: AppLogger.data)
                return expired.data
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
            let cacheKey = "questions_\(language.rawValue)"
            let cachedDataWithMetadata = cacheManager.getCachedDataWithMetadata([Question].self, for: cacheKey)
            
            // Fetch remote questions with ETag support
            let response = try await loadFromRemoteWithETag(
                language: language,
                cachedEtag: cachedDataWithMetadata?.etag,
                cachedData: cachedDataWithMetadata?.data
            )
            
            let remoteCount = response.data.count
            let cachedCount = cachedDataWithMetadata?.data.count ?? 0
            let cachedEtag = cachedDataWithMetadata?.etag
            
            // Check if there are updates based on ETag or count
            let etagChanged = (response.etag != cachedEtag) && (response.etag != nil)
            let countChanged = remoteCount != cachedCount
            let updates = etagChanged || countChanged
            
            await MainActor.run {
                remoteQuestionsCount = remoteCount
                cachedQuestionsCount = cachedCount
                hasUpdates = updates
                
                AppLogger.info(
                    "Update check: Remote=\(remoteCount), Cached=\(cachedCount), ETagChanged=\(etagChanged), CountChanged=\(countChanged), HasUpdates=\(updates)",
                    category: AppLogger.network
                )
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
            let cacheKey = "questions_\(language.rawValue)"
            let cachedDataWithMetadata = cacheManager.getCachedDataWithMetadata([Question].self, for: cacheKey)
            
            // Use ETag-based loading with validation
            let response = try await loadFromRemoteWithETag(
                language: language,
                cachedEtag: cachedDataWithMetadata?.etag,
                cachedData: cachedDataWithMetadata?.data
            )
            
            // Clear old cache and save new data with ETag
            cacheManager.invalidateCache(for: cacheKey)
            cacheManager.cacheData(
                response.data,
                for: cacheKey,
                etag: response.etag ?? cachedDataWithMetadata?.etag,
                lastModified: response.lastModified ?? cachedDataWithMetadata?.lastModified
            )
            
            await MainActor.run {
                lastUpdateDate = Date()
                hasUpdates = false
                cachedQuestionsCount = response.data.count
                remoteQuestionsCount = response.data.count
            }
            
            AppLogger.info("Force sync completed: \(response.data.count) questions with ETag: \(response.etag ?? cachedDataWithMetadata?.etag ?? "none")", category: AppLogger.network)
            return response.data
            
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
    
    private func loadFromRemoteWithETag(
        language: AppLanguage,
        cachedEtag: String?,
        cachedData: [Question]?
    ) async throws -> NetworkResponse<[Question]> {
        let fileName = language == .russian ? "questions.json" : "questions_en.json"
        let urlString = "\(baseURL)/\(fileName)"
        
        AppLogger.info("EnhancedRemoteQuestionsService: Attempting to fetch from \(urlString) with ETag support", category: AppLogger.network)
        
        // Make request with ETag support
        // Note: We pass nil for cachedData because RemoteQuestion doesn't have a memberwise init
        // Instead, we'll handle 304 response by returning our cached [Question] data
        let response = try await networkManager.requestWithMetadata(
            url: urlString,
            responseType: [RemoteQuestion].self,
            cachedEtag: cachedEtag,
            cachedData: nil
        )
        
        // If 304 Not Modified, return cached Question data
        if response.notModified {
            guard let cachedQuestions = cachedData else {
                throw NetworkError.unknownError(NSError(domain: "No cached data for 304 response", code: 304))
            }
            AppLogger.info("EnhancedRemoteQuestionsService: Content not modified (304), using cached questions", category: AppLogger.network)
            return NetworkResponse(
                data: cachedQuestions,
                etag: response.etag ?? cachedEtag,
                lastModified: response.lastModified,
                statusCode: response.statusCode
            )
        }
        
        // If content was modified (200), convert and validate
        let questions = response.data.map { $0.toQuestion() }
        
        // Validate questions
        let validator = QuestionValidator()
        do {
            try validator.validate(questions)
            AppLogger.info("EnhancedRemoteQuestionsService: Validated \(questions.count) questions successfully", category: AppLogger.network)
        } catch {
            AppLogger.error("EnhancedRemoteQuestionsService: Validation failed", error: error, category: AppLogger.network)
            throw error
        }
        
        return NetworkResponse(
            data: questions,
            etag: response.etag,
            lastModified: response.lastModified,
            statusCode: response.statusCode
        )
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
