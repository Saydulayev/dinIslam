//
//  Protocols.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

// MARK: - Manager Protocols
protocol StatsManagerProtocol {
    var stats: UserStats { get }
    func updateStats(correctCount: Int, totalCount: Int, wrongQuestionIds: [String], percentage: Double)
    func clearWrongQuestions()
    func removeWrongQuestion(_ questionId: String)
    func getWrongQuestions(from allQuestions: [Question]) -> [Question]
    func resetStats()
    func getCorrectedMistakesCount() -> Int
}

protocol AchievementManagerProtocol {
    var newAchievements: [Achievement] { get }
    func checkAchievements(for stats: UserStats, quizResult: QuizResult?)
    func clearNewAchievements()
}

protocol HapticManagerProtocol {
    func selectionChanged()
    func success()
    func error()
}

protocol SoundManagerProtocol {
    func playSuccessSound()
    func playErrorSound()
    func playSelectionSound()
}

protocol NotificationManagerProtocol {
    func requestPermission() async -> Bool
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval)
    func cancelAllNotifications()
}

// MARK: - Repository Protocols
protocol QuestionsRepositoryProtocol {
    func loadQuestions(language: String) async throws -> [Question]
}

protocol EnhancedQuestionsRepositoryProtocol: QuestionsRepositoryProtocol {
    func preloadQuestions(for languages: [String]) async
    func getCacheStatus() -> CacheStatus
    func clearCache() async
}

// MARK: - Use Case Protocols
protocol QuizUseCaseProtocol {
    func startQuiz(language: String) async throws -> [Question]
    func loadAllQuestions(language: String) async throws -> [Question]
    func shuffleAnswers(for question: Question) -> Question
    func calculateResult(correctAnswers: Int, totalQuestions: Int, timeSpent: TimeInterval) -> QuizResult
}

protocol EnhancedQuizUseCaseProtocol: QuizUseCaseProtocol {
    func preloadQuestions(for languages: [String]) async
    func getCacheStatus() -> CacheStatus
    func clearCache() async
}

// MARK: - Network Protocols
protocol NetworkManagerProtocol {
    var isConnected: Bool { get }
    func request<T: Codable>(url: String, responseType: T.Type, retryCount: Int) async throws -> T
}

// MARK: - Cache Protocols
protocol CacheManagerProtocol {
    func get<T: Codable>(key: String, type: T.Type) -> T?
    func set<T: Codable>(key: String, value: T, ttl: TimeInterval?)
    func remove(key: String)
    func clear()
    func getStatus() -> CacheStatus
}

// MARK: - Settings Protocols
protocol SettingsManagerProtocol {
    var settings: AppSettings { get }
    func updateLanguage(_ language: AppLanguage)
    func updateSoundEnabled(_ enabled: Bool)
    func updateHapticEnabled(_ enabled: Bool)
    func updateNotificationsEnabled(_ enabled: Bool)
}
