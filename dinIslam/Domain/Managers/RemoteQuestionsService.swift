//
//  RemoteQuestionsService.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Combine
import OSLog

class RemoteQuestionsService: ObservableObject {
    @Published var isLoading = false
    @Published var lastUpdateDate: Date?
    @Published var hasUpdates = false
    @Published var remoteQuestionsCount = 0
    @Published var cachedQuestionsCount = 0
    
    private let baseURL = "https://raw.githubusercontent.com/Saydulayev/dinIslam-questions/main"
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cached_questions"
    private let lastUpdateKey = "last_questions_update"
    
    // MARK: - Public Methods
    
    func fetchQuestions(for language: AppLanguage) async -> [Question] {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            // Try to fetch from remote
            let remoteQuestions = try await loadFromRemote(language: language)
            
            // Cache the questions locally
            await cacheQuestions(remoteQuestions, for: language)
            
            // Update last update date
            await MainActor.run {
                lastUpdateDate = Date()
                userDefaults.set(Date(), forKey: lastUpdateKey)
            }
            
            return remoteQuestions
        } catch {
            AppLogger.error("Failed to fetch remote questions", error: error, category: AppLogger.network)
            
            // Fallback to cached questions
            if let cachedQuestions = getCachedQuestions(for: language) {
                return cachedQuestions
            }
            
            // Final fallback to local questions
            return loadLocalQuestions(for: language)
        }
    }
    
    func getCachedQuestions(for language: AppLanguage) -> [Question]? {
        let cacheKey = "\(self.cacheKey)_\(language.rawValue)"
        guard let data = userDefaults.data(forKey: cacheKey),
              let questions = try? JSONDecoder().decode([Question].self, from: data) else {
            return nil
        }
        return questions
    }
    
    func shouldUpdateQuestions() -> Bool {
        guard let lastUpdate = userDefaults.object(forKey: lastUpdateKey) as? Date else {
            return true // First time, should update
        }
        
        // Update if more than 24 hours have passed
        return Date().timeIntervalSince(lastUpdate) > 24 * 60 * 60
    }
    
    // MARK: - Private Methods
    
    private func loadFromRemote(language: AppLanguage) async throws -> [Question] {
        let fileName = language == .russian ? "questions.json" : "questions_en.json"
        let urlString = "\(baseURL)/\(fileName)"
        
        AppLogger.info("RemoteQuestionsService: Attempting to fetch from \(urlString)", category: AppLogger.network)
        
        guard let url = URL(string: urlString) else {
            AppLogger.error("RemoteQuestionsError: Invalid URL for \(fileName)", category: AppLogger.network)
            throw RemoteQuestionsError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RemoteQuestionsError.invalidResponse
        }
        
        // Invalid questions are skipped; throws only when no valid question is left
        let questions: [Question]
        do {
            questions = try QuestionsFile.decode(data)
        } catch {
            AppLogger.error("RemoteQuestionsService: Failed to decode \(fileName)", error: error, category: AppLogger.network)
            throw RemoteQuestionsError.decodingError
        }
        AppLogger.info("RemoteQuestionsService: Loaded \(questions.count) valid questions from \(fileName)", category: AppLogger.network)
        
        return questions
    }
    
    private func cacheQuestions(_ questions: [Question], for language: AppLanguage) async {
        let cacheKey = "\(self.cacheKey)_\(language.rawValue)"
        
        do {
            let data = try JSONEncoder().encode(questions)
            userDefaults.set(data, forKey: cacheKey)
            AppLogger.info("RemoteQuestionsService: Cached \(questions.count) questions for \(language.rawValue)", category: AppLogger.data)
            
            #if DEBUG
            AppLogger.debug("Cached question IDs: \(questions.map { $0.id }.joined(separator: ", "))", category: AppLogger.data)
            
            // Проверяем, есть ли q31 в кэше
            if questions.contains(where: { $0.id == "q31" }) {
                AppLogger.debug("q31 is cached successfully!", category: AppLogger.data)
            } else {
                AppLogger.debug("q31 NOT cached", category: AppLogger.data)
            }
            #endif
        } catch {
            AppLogger.error("Failed to cache questions", error: error, category: AppLogger.data)
        }
    }
    
    private func loadLocalQuestions(for language: AppLanguage) -> [Question] {
        do {
            return try QuestionsFile.loadBundled(for: language)
        } catch {
            AppLogger.error("RemoteQuestionsService: Failed to load local questions", error: error, category: AppLogger.data)
            return []
        }
    }
    // MARK: - Update Check Methods
    
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
            // Get remote questions count
            let remoteQuestions = try await loadFromRemote(language: language)
            let remoteCount = remoteQuestions.count
            
            // Get cached questions count
            let cachedQuestions = getCachedQuestions(for: language) ?? []
            let cachedCount = cachedQuestions.count
            
            await MainActor.run {
                remoteQuestionsCount = remoteCount
                cachedQuestionsCount = cachedCount
                // Use != instead of > to detect both additions and content changes
                hasUpdates = remoteCount != cachedCount
                
                AppLogger.info("Update check: Remote=\(remoteCount), Cached=\(cachedCount), HasUpdates=\(hasUpdates)", category: AppLogger.network)
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
            // Force fetch from remote
            let remoteQuestions = try await loadFromRemote(language: language)
            
            // Cache the questions locally
            await cacheQuestions(remoteQuestions, for: language)
            
            // Update last update date
            await MainActor.run {
                lastUpdateDate = Date()
                userDefaults.set(Date(), forKey: lastUpdateKey)
                hasUpdates = false
                cachedQuestionsCount = remoteQuestions.count
                remoteQuestionsCount = remoteQuestions.count
            }
            
            AppLogger.info("Force sync completed: \(remoteQuestions.count) questions", category: AppLogger.network)
            return remoteQuestions
        } catch {
            AppLogger.error("Force sync failed", error: error, category: AppLogger.network)
            return getCachedQuestions(for: language) ?? []
        }
    }
}

// MARK: - Errors

enum RemoteQuestionsError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for remote questions"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode questions"
        }
    }
}
