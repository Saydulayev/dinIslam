//
//  EnhancedRemoteQuestionsService.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Combine
import Observation
import OSLog

// MARK: - Cache Configuration
struct CacheConfiguration {
    let ttl: TimeInterval
    let maxCacheSize: Int
    let compressionEnabled: Bool
    
    static let `default` = CacheConfiguration(
        ttl: 24 * 60 * 60, // 24 hours; after that the file is revalidated via ETag (304 if unchanged)
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
    
    /// - Parameter cacheDirectory: custom cache folder (used by tests); defaults to Caches/QuestionsCache.
    init(configuration: CacheConfiguration = .default, cacheDirectory: URL? = nil) {
        self.configuration = configuration
        
        if let cacheDirectory {
            self.cacheDirectory = cacheDirectory
        } else {
            // Create cache directory (fallback to temporaryDirectory if caches URL is unavailable)
            let cachesPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
            self.cacheDirectory = cachesPath.appendingPathComponent("QuestionsCache")
        }
        
        try? fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
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
/// @Observable: экраны получают сервис через кастомный @Environment-ключ,
/// и SwiftUI отслеживает чтение свойств только у @Observable-объектов
@Observable
class EnhancedRemoteQuestionsService {
    var isLoading = false
    var lastUpdateDate: Date?
    var hasUpdates = false
    var remoteQuestionsCount = 0
    var cachedQuestionsCount = 0
    var networkStatus: NetworkStatus = .unknown
    
    @ObservationIgnored private let baseURL = "https://raw.githubusercontent.com/Saydulayev/dinIslam-questions/main"
    @ObservationIgnored private let networkManager: NetworkManager
    @ObservationIgnored private let cacheManager: CacheManager
    @ObservationIgnored private let configuration: CacheConfiguration
    @ObservationIgnored private var networkStatusCancellable: AnyCancellable?
    
    /// Разобранные вопросы по языку: файл кэша читается и разбирается один раз за запуск
    @ObservationIgnored private var memoryCache: [AppLanguage: CachedQuestions] = [:]
    /// Встроенные вопросы, если ни сети, ни кэша нет
    @ObservationIgnored private var bundledQuestions: [AppLanguage: [Question]] = [:]
    /// Идущие запросы к GitHub: одновременные вызовы ждут один запрос
    @ObservationIgnored private var refreshTasks: [AppLanguage: Task<[Question], Error>] = [:]
    /// Языки, для которых банк уже сверялся с GitHub за этот запуск
    @ObservationIgnored private var revalidatedLanguages: Set<AppLanguage> = []
    
    private struct CachedQuestions {
        let questions: [Question]
        let etag: String?
        let lastModified: Date?
        let timestamp: Date
    }
    
    init(
        networkManager: NetworkManager = NetworkManager(),
        cacheManager: CacheManager = CacheManager(),
        configuration: CacheConfiguration = .default
    ) {
        self.networkManager = networkManager
        self.cacheManager = cacheManager
        self.configuration = configuration
        
        // Кэш прежнего формата не содержит тем и объяснений, а при неизменном ETag (304) обновился бы не скоро
        AppLanguage.allCases.forEach { cacheManager.invalidateCache(for: "questions_\($0.rawValue)") }
        
        // Subscribe to network status changes
        networkStatusCancellable = networkManager.$isConnected
            .map { $0 ? NetworkStatus.connected : NetworkStatus.disconnected }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.networkStatus = status
            }
    }
    
    /// Версия в ключе сбрасывает кэш, когда в модели Question появляются новые поля
    static func cacheKey(for language: AppLanguage) -> String {
        "questions_v2_\(language.rawValue)"
    }
    
    // MARK: - Public Methods
    
    /// Вопросы для викторины. Кэш (даже просроченный) отдаётся сразу, а просроченный обновляется в фоне —
    /// новые вопросы появятся со следующей викторины. Сеть ждём, только если кэша нет; без сети — встроенные вопросы.
    func fetchQuestions(
        for language: AppLanguage,
        manageLoadingState: Bool = true
    ) async -> [Question] {
        if let cached = cachedQuestions(for: language) {
            cachedQuestionsCount = cached.questions.count
            if isExpired(cached) {
                AppLogger.info("Cache expired for \(language.rawValue), refreshing in background", category: AppLogger.data)
                refreshInBackground(language)
            }
            return cached.questions
        }
        
        if manageLoadingState {
            isLoading = true
        }
        defer {
            if manageLoadingState {
                isLoading = false
            }
        }
        
        do {
            return try await refresh(language)
        } catch {
            AppLogger.error("Failed to fetch remote questions, using bundled questions", error: error, category: AppLogger.network)
            return loadLocalQuestions(for: language)
        }
    }
    
    /// Прогревает кэш в памяти и один раз за запуск сверяет банк с GitHub (по ETag, обычно ответ 304).
    func preloadQuestions(for language: AppLanguage) async {
        _ = await fetchQuestions(for: language, manageLoadingState: false)
        if !revalidatedLanguages.contains(language) {
            refreshInBackground(language)
        }
    }
    
    func checkForUpdates(for language: AppLanguage) async {
        isLoading = true
        defer {
            isLoading = false
        }
        
        do {
            let cached = cachedQuestions(for: language)
            
            // Fetch remote questions with ETag support
            let response = try await loadFromRemoteWithETag(
                language: language,
                cachedEtag: cached?.etag,
                cachedData: cached?.questions
            )
            
            let remoteCount = response.data.count
            let cachedCount = cached?.questions.count ?? 0
            let cachedEtag = cached?.etag
            
            // Check if there are updates based on ETag or count
            let etagChanged = (response.etag != cachedEtag) && (response.etag != nil)
            let countChanged = remoteCount != cachedCount
            let updates = etagChanged || countChanged
            
            remoteQuestionsCount = remoteCount
            cachedQuestionsCount = cachedCount
            hasUpdates = updates
            
            AppLogger.info(
                "Update check: Remote=\(remoteCount), Cached=\(cachedCount), ETagChanged=\(etagChanged), CountChanged=\(countChanged), HasUpdates=\(updates)",
                category: AppLogger.network
            )
        } catch {
            AppLogger.error("Failed to check for updates", error: error, category: AppLogger.network)
            hasUpdates = false
        }
    }
    
    func forceSync(for language: AppLanguage) async -> [Question] {
        AppLogger.info("Force sync started for \(language.rawValue)", category: AppLogger.network)
        
        isLoading = true
        defer {
            isLoading = false
        }
        
        do {
            let questions = try await refresh(language)
            hasUpdates = false
            AppLogger.info("Force sync completed: \(questions.count) questions", category: AppLogger.network)
            return questions
        } catch {
            AppLogger.error("Force sync failed", error: error, category: AppLogger.network)
            return cachedQuestions(for: language)?.questions ?? []
        }
    }
    
    /// Идущее обновление из GitHub (для тестов: дождаться фонового обновления)
    func pendingRefresh(for language: AppLanguage) -> Task<[Question], Error>? {
        refreshTasks[language]
    }
    
    /// Удаляет кэш старой системы загрузки (RemoteQuestionsService хранил вопросы в UserDefaults).
    static func removeLegacyCache(from userDefaults: UserDefaults = .standard) {
        let legacyKeys = AppLanguage.allCases.map { "cached_questions_\($0.rawValue)" } + ["last_questions_update"]
        legacyKeys.forEach { userDefaults.removeObject(forKey: $0) }
    }
    
    func clearCache() {
        cacheManager.clearAllCache()
        memoryCache.removeAll()
        AppLogger.info("Cache cleared", category: AppLogger.data)
    }
    
    func getCacheInfo() -> (size: Int64, entries: Int) {
        let size = cacheManager.getCacheSize()
        let entries = cacheManager.getCacheEntriesCount()
        return (size, entries)
    }
    
    // MARK: - Private Methods
    
    /// Кэш из памяти, при первом обращении за запуск — из файла
    private func cachedQuestions(for language: AppLanguage) -> CachedQuestions? {
        if let cached = memoryCache[language] {
            return cached
        }
        guard let stored = cacheManager.getCachedDataWithMetadata([Question].self, for: Self.cacheKey(for: language)) else {
            return nil
        }
        let cached = CachedQuestions(
            questions: stored.data,
            etag: stored.etag,
            lastModified: stored.lastModified,
            timestamp: stored.timestamp
        )
        memoryCache[language] = cached
        return cached
    }
    
    private func isExpired(_ cached: CachedQuestions) -> Bool {
        Date().timeIntervalSince(cached.timestamp) > configuration.ttl
    }
    
    private func refreshInBackground(_ language: AppLanguage) {
        startRefresh(language)
    }
    
    private func refresh(_ language: AppLanguage) async throws -> [Question] {
        try await startRefresh(language).value
    }
    
    /// Загружает банк из GitHub (по ETag) и обновляет кэш; пока запрос идёт, новые вызовы получают его же
    @discardableResult
    private func startRefresh(_ language: AppLanguage) -> Task<[Question], Error> {
        if let running = refreshTasks[language] {
            return running
        }
        let task = Task {
            defer { refreshTasks[language] = nil }
            return try await downloadAndCache(language)
        }
        refreshTasks[language] = task
        return task
    }
    
    private func downloadAndCache(_ language: AppLanguage) async throws -> [Question] {
        let cacheKey = Self.cacheKey(for: language)
        let cached = cachedQuestions(for: language)
        
        let response = try await loadFromRemoteWithETag(
            language: language,
            cachedEtag: cached?.etag,
            cachedData: cached?.questions
        )
        
        // Cache the data to refresh timestamp (revalidation) and persist new metadata when updated.
        let etag = response.etag ?? cached?.etag
        let lastModified = response.lastModified ?? cached?.lastModified
        cacheManager.cacheData(response.data, for: cacheKey, etag: etag, lastModified: lastModified)
        memoryCache[language] = CachedQuestions(
            questions: response.data,
            etag: etag,
            lastModified: lastModified,
            timestamp: Date()
        )
        revalidatedLanguages.insert(language)
        
        if response.notModified {
            AppLogger.info("Cache revalidated via 304 Not Modified for \(language.rawValue)", category: AppLogger.data)
        } else {
            AppLogger.info("Cached updated questions with ETag: \(response.etag ?? "none")", category: AppLogger.data)
        }
        
        lastUpdateDate = Date()
        remoteQuestionsCount = response.data.count
        cachedQuestionsCount = response.data.count
        return response.data
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
        // Note: We pass nil for cachedData; on 304 we return our cached [Question] data instead.
        // LossyDecodable: a question that can't be decoded is skipped, not the whole file.
        let response = try await networkManager.requestWithMetadata(
            url: urlString,
            responseType: [LossyDecodable<RemoteQuestion>].self,
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
        
        // If content was modified (200), convert and validate: invalid questions are skipped,
        // the file is rejected only when no valid question is left
        let questions = try QuestionsFile.questions(from: response.data)
        AppLogger.info("EnhancedRemoteQuestionsService: Loaded \(questions.count) valid questions", category: AppLogger.network)
        
        return NetworkResponse(
            data: questions,
            etag: response.etag,
            lastModified: response.lastModified,
            statusCode: response.statusCode
        )
    }
    
    private func loadLocalQuestions(for language: AppLanguage) -> [Question] {
        if let bundled = bundledQuestions[language] {
            return bundled
        }
        do {
            let questions = try QuestionsFile.loadBundled(for: language)
            bundledQuestions[language] = questions
            return questions
        } catch {
            AppLogger.error("Failed to load local questions for \(language.rawValue)", error: error, category: AppLogger.data)
            return []
        }
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
