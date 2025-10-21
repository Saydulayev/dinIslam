//
//  RemoteQuestionsService.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Combine

class RemoteQuestionsService: ObservableObject {
    @Published var isLoading = false
    @Published var lastUpdateDate: Date?
    
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
            print("Failed to fetch remote questions: \(error)")
            
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
        
        print("🔄 RemoteQuestionsService: Attempting to fetch from \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ RemoteQuestionsError: Invalid URL for \(fileName)")
            throw RemoteQuestionsError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RemoteQuestionsError.invalidResponse
        }
        
        let remoteQuestions = try JSONDecoder().decode([RemoteQuestion].self, from: data)
        print("✅ RemoteQuestionsService: Successfully loaded \(remoteQuestions.count) questions from \(fileName)")
        return remoteQuestions.map { $0.toQuestion() }
    }
    
    private func cacheQuestions(_ questions: [Question], for language: AppLanguage) async {
        let cacheKey = "\(self.cacheKey)_\(language.rawValue)"
        
        do {
            let data = try JSONEncoder().encode(questions)
            userDefaults.set(data, forKey: cacheKey)
            print("💾 RemoteQuestionsService: Cached \(questions.count) questions for \(language.rawValue)")
        } catch {
            print("❌ Failed to cache questions: \(error)")
        }
    }
    
    private func loadLocalQuestions(for language: AppLanguage) -> [Question] {
        let fileName = language == .russian ? "questions" : "questions_en"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let questions = try? JSONDecoder().decode([Question].self, from: data) else {
            return []
        }
        
        return questions
    }
}

// MARK: - Remote Question Models

struct RemoteQuestion: Codable {
    let id: String
    let text: String
    let answers: [RemoteAnswer]
    let correctIndex: Int
    let category: String
    let difficulty: String
    
    func toQuestion() -> Question {
        return Question(
            id: id,
            text: text,
            answers: answers.map { $0.toAnswer() },
            correctIndex: correctIndex,
            category: category,
            difficulty: .medium // Default difficulty since we're simplifying
        )
    }
}

struct RemoteAnswer: Codable {
    let id: String
    let text: String
    
    func toAnswer() -> Answer {
        return Answer(id: id, text: text)
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
