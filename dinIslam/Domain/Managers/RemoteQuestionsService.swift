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
        
        let remoteQuestions = try JSONDecoder().decode([RemoteQuestion].self, from: data)
        AppLogger.info("RemoteQuestionsService: Successfully loaded \(remoteQuestions.count) questions from \(fileName)", category: AppLogger.network)
        
        #if DEBUG
        // Преобразуем ID в строки для логирования
        let questionIds = remoteQuestions.map { question -> String in
            switch question.id {
            case .string(let str):
                return str
            case .int(let num):
                return String(num)
            }
        }
        AppLogger.debug("Remote question IDs: \(questionIds.joined(separator: ", "))", category: AppLogger.network)
        
        // Проверяем, есть ли q31
        let hasQ31 = questionIds.contains("q31")
        if hasQ31 {
            AppLogger.debug("Found q31 in remote questions!", category: AppLogger.network)
        } else {
            AppLogger.debug("q31 NOT found in remote questions", category: AppLogger.network)
        }
        #endif
        
        let questions = remoteQuestions.map { $0.toQuestion() }
        
        // Validate questions before returning
        let validator = QuestionValidator()
        do {
            try validator.validate(questions)
            AppLogger.info("RemoteQuestionsService: All \(questions.count) questions validated successfully", category: AppLogger.network)
        } catch let validationError as ValidationError {
            AppLogger.error("RemoteQuestionsService: Validation failed", error: validationError, category: AppLogger.network)
            throw RemoteQuestionsError.decodingError
        }
        
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
        let fileName = language == .russian ? "questions" : "questions_en"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let questions = try? JSONDecoder().decode([Question].self, from: data) else {
            return []
        }
        
        // Validate local questions
        let validator = QuestionValidator()
        do {
            try validator.validate(questions)
            AppLogger.info("RemoteQuestionsService: Local questions validated successfully (\(questions.count) questions)", category: AppLogger.data)
        } catch {
            AppLogger.error("RemoteQuestionsService: Local questions validation failed", error: error, category: AppLogger.data)
            // Return empty array if local questions are invalid
            return []
        }
        
        return questions
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

// MARK: - Remote Question Models

// Поддержка обоих форматов: старый (id/text/answers с id) и новый (id/question/answers как массив строк)
struct RemoteQuestion: Codable {
    // ID может быть строкой или числом
    let id: RemoteQuestionID
    let text: String?
    let question: String?  // Новый формат использует "question" вместо "text"
    let answers: RemoteAnswers
    let correctIndex: Int
    let category: String?
    let difficulty: String?
    
    // Определяем текст вопроса из любого формата
    var questionText: String {
        return text ?? question ?? ""
    }
    
    // Определяем категорию с дефолтным значением
    var questionCategory: String {
        return category ?? "Общее"
    }
    
    func toQuestion() -> Question {
        // Преобразуем ID в строку
        let questionId: String
        switch id {
        case .string(let str):
            questionId = str
        case .int(let num):
            questionId = String(num)
        }
        
        // Преобразуем answers в нужный формат
        let questionAnswers: [Answer]
        switch answers {
        case .objects(let answerObjects):
            questionAnswers = answerObjects.map { $0.toAnswer() }
        case .strings(let answerStrings):
            // Генерируем ID для строковых ответов
            questionAnswers = answerStrings.enumerated().map { index, text in
                Answer(id: "a\(index + 1)", text: text)
            }
        }
        
        // Определяем difficulty
        let questionDifficulty: Difficulty
        if let difficultyStr = difficulty,
           let parsedDifficulty = Difficulty(rawValue: difficultyStr.lowercased()) {
            questionDifficulty = parsedDifficulty
        } else {
            questionDifficulty = .medium
        }
        
        return Question(
            id: questionId,
            text: questionText,
            answers: questionAnswers,
            correctIndex: correctIndex,
            category: questionCategory,
            difficulty: questionDifficulty
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case id, text, question, answers, correctIndex, category, difficulty
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Обрабатываем ID (может быть строкой или числом)
        if let stringId = try? container.decode(String.self, forKey: .id) {
            id = .string(stringId)
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            id = .int(intId)
        } else {
            throw DecodingError.typeMismatch(
                RemoteQuestionID.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath + [CodingKeys.id],
                    debugDescription: "ID must be either String or Int"
                )
            )
        }
        
        // Обрабатываем текст вопроса (может быть "text" или "question")
        text = try? container.decode(String.self, forKey: .text)
        question = try? container.decode(String.self, forKey: .question)
        
        // Обрабатываем answers (может быть массив объектов или массив строк)
        if let answerObjects = try? container.decode([RemoteAnswer].self, forKey: .answers) {
            answers = .objects(answerObjects)
        } else if let answerStrings = try? container.decode([String].self, forKey: .answers) {
            answers = .strings(answerStrings)
        } else {
            throw DecodingError.typeMismatch(
                RemoteAnswers.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath + [CodingKeys.answers],
                    debugDescription: "Answers must be either array of objects or array of strings"
                )
            )
        }
        
        correctIndex = try container.decode(Int.self, forKey: .correctIndex)
        category = try? container.decode(String.self, forKey: .category)
        difficulty = try? container.decode(String.self, forKey: .difficulty)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Кодируем ID
        switch id {
        case .string(let str):
            try container.encode(str, forKey: .id)
        case .int(let num):
            try container.encode(num, forKey: .id)
        }
        
        // Кодируем текст (приоритет text над question для обратной совместимости)
        if let text = text {
            try container.encode(text, forKey: .text)
        } else if let question = question {
            try container.encode(question, forKey: .question)
        }
        
        // Кодируем answers
        switch answers {
        case .objects(let answerObjects):
            try container.encode(answerObjects, forKey: .answers)
        case .strings(let answerStrings):
            try container.encode(answerStrings, forKey: .answers)
        }
        
        try container.encode(correctIndex, forKey: .correctIndex)
        if let category = category {
            try container.encode(category, forKey: .category)
        }
        if let difficulty = difficulty {
            try container.encode(difficulty, forKey: .difficulty)
        }
    }
}

enum RemoteQuestionID: Codable {
    case string(String)
    case int(Int)
}

enum RemoteAnswers: Codable {
    case objects([RemoteAnswer])
    case strings([String])
}

struct RemoteAnswer: Codable {
    let id: String?
    let text: String
    
    func toAnswer() -> Answer {
        return Answer(id: id ?? UUID().uuidString, text: text)
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
