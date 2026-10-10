//
//  UserProfile.swift
//  dinIslam
//
//  Created by Saydulayev on 12.01.26.
//

import Foundation
#if os(iOS)
import UIKit
#endif

// MARK: - User Profile
struct UserProfile: Codable, Identifiable, Equatable {
    enum AuthMethod: String, Codable {
        case anonymous
        case signInWithApple
    }

    struct Metadata: Codable, Equatable {
        var createdAt: Date
        var updatedAt: Date
        var lastSyncedAt: Date?
        var lastDeviceIdentifier: String?
    }

    var id: String
    var authMethod: AuthMethod
    var fullName: String?
    var customDisplayName: String?  // Пользовательское отображаемое имя
    var localeIdentifier: String
    var avatarURL: URL?
    var progress: ProfileProgress
    var preferences: ProfilePreferences
    var metadata: Metadata

    init(
        id: String,
        authMethod: AuthMethod,
        fullName: String? = nil,
        customDisplayName: String? = nil,
        localeIdentifier: String = Locale.current.identifier,
        avatarURL: URL? = nil,
        progress: ProfileProgress = ProfileProgress(),
        preferences: ProfilePreferences = ProfilePreferences(),
        metadata: Metadata = Metadata(
            createdAt: Date(),
            updatedAt: Date(),
            lastSyncedAt: nil,
            lastDeviceIdentifier: UIDeviceIdentifierProvider.currentIdentifier()
        )
    ) {
        self.id = id
        self.authMethod = authMethod
        self.fullName = fullName
        self.customDisplayName = customDisplayName
        self.localeIdentifier = localeIdentifier
        self.avatarURL = avatarURL
        self.progress = progress
        self.preferences = preferences
        self.metadata = metadata
    }
}

// MARK: - Profile Progress
struct ProfileProgress: Codable, Equatable {
    var totalQuestionsAnswered: Int
    var correctAnswers: Int
    var incorrectAnswers: Int
    var correctedMistakes: Int
    var examsPassed: Int
    var examsTaken: Int
    var currentStreak: Int
    var longestStreak: Int
    var averageQuizScore: Double
    var masteryLevel: MasteryLevel
    var difficultyStats: [DifficultyPerformance]
    var topicProgress: [TopicProgress]
    var recommendations: [LearningRecommendation]
    var quizHistory: [QuizHistoryEntry]
    var examHistory: [ExamHistoryEntry]
    var lastActivityAt: Date?

    enum CodingKeys: String, CodingKey {
        case totalQuestionsAnswered
        case correctAnswers
        case incorrectAnswers
        case correctedMistakes
        case examsPassed
        case examsTaken
        case currentStreak
        case longestStreak
        case averageQuizScore
        case masteryLevel
        case difficultyStats
        case topicProgress
        case recommendations
        case quizHistory
        case examHistory
        case lastActivityAt
    }

    init(
        totalQuestionsAnswered: Int = 0,
        correctAnswers: Int = 0,
        incorrectAnswers: Int = 0,
        correctedMistakes: Int = 0,
        examsPassed: Int = 0,
        examsTaken: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        averageQuizScore: Double = 0,
        masteryLevel: MasteryLevel = .novice,
        difficultyStats: [DifficultyPerformance] = Difficulty.allCases.map { DifficultyPerformance(difficulty: $0) },
        topicProgress: [TopicProgress] = [],
        recommendations: [LearningRecommendation] = [],
        quizHistory: [QuizHistoryEntry] = [],
        examHistory: [ExamHistoryEntry] = [],
        lastActivityAt: Date? = nil
    ) {
        self.totalQuestionsAnswered = totalQuestionsAnswered
        self.correctAnswers = correctAnswers
        self.incorrectAnswers = incorrectAnswers
        self.correctedMistakes = correctedMistakes
        self.examsPassed = examsPassed
        self.examsTaken = examsTaken
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.averageQuizScore = averageQuizScore
        self.masteryLevel = masteryLevel
        self.difficultyStats = difficultyStats
        self.topicProgress = topicProgress
        self.recommendations = recommendations
        self.quizHistory = quizHistory
        self.examHistory = examHistory
        self.lastActivityAt = lastActivityAt
    }
    
    init(from decoder: Decoder) throws {
        // Каждое поле читается отдельно, массивы — поэлементно (см. StoredDataDecoding.swift)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ProfileProgress()
        totalQuestionsAnswered = container.decode(.totalQuestionsAnswered, default: 0)
        correctAnswers = container.decode(.correctAnswers, default: 0)
        incorrectAnswers = container.decode(.incorrectAnswers, default: 0)
        correctedMistakes = container.decode(.correctedMistakes, default: 0)
        examsPassed = container.decode(.examsPassed, default: 0)
        examsTaken = container.decode(.examsTaken, default: 0)
        currentStreak = container.decode(.currentStreak, default: 0)
        longestStreak = container.decode(.longestStreak, default: 0)
        averageQuizScore = container.decode(.averageQuizScore, default: 0)
        masteryLevel = container.decode(.masteryLevel, default: defaults.masteryLevel)
        difficultyStats = container.decodeLossyArray(.difficultyStats, default: defaults.difficultyStats)
        topicProgress = container.decodeLossyArray(.topicProgress)
        recommendations = container.decodeLossyArray(.recommendations)
        quizHistory = container.decodeLossyArray(.quizHistory)
        examHistory = container.decodeLossyArray(.examHistory)
        lastActivityAt = container.decodeOptional(.lastActivityAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalQuestionsAnswered, forKey: .totalQuestionsAnswered)
        try container.encode(correctAnswers, forKey: .correctAnswers)
        try container.encode(incorrectAnswers, forKey: .incorrectAnswers)
        try container.encode(correctedMistakes, forKey: .correctedMistakes)
        try container.encode(examsPassed, forKey: .examsPassed)
        try container.encode(examsTaken, forKey: .examsTaken)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(longestStreak, forKey: .longestStreak)
        try container.encode(averageQuizScore, forKey: .averageQuizScore)
        try container.encode(masteryLevel, forKey: .masteryLevel)
        try container.encode(difficultyStats, forKey: .difficultyStats)
        try container.encode(topicProgress, forKey: .topicProgress)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(quizHistory, forKey: .quizHistory)
        try container.encode(examHistory, forKey: .examHistory)
        try container.encodeIfPresent(lastActivityAt, forKey: .lastActivityAt)
    }
}

// MARK: - Profile Preferences
struct ProfilePreferences: Codable, Equatable {
    var preferredDifficulty: Difficulty?
    var dailyGoal: Int
    var notificationsEnabled: Bool
    var syncedSettings: Bool
    var preferredStudyTopics: [String]

    init(
        preferredDifficulty: Difficulty? = nil,
        dailyGoal: Int = 10,
        notificationsEnabled: Bool = true,
        syncedSettings: Bool = false,
        preferredStudyTopics: [String] = []
    ) {
        self.preferredDifficulty = preferredDifficulty
        self.dailyGoal = dailyGoal
        self.notificationsEnabled = notificationsEnabled
        self.syncedSettings = syncedSettings
        self.preferredStudyTopics = preferredStudyTopics
    }
}

// MARK: - Difficulty Performance
struct DifficultyPerformance: Codable, Equatable, Identifiable {
    var id: Difficulty { difficulty }
    var difficulty: Difficulty
    var correctAnswers: Int
    var totalAnswers: Int
    var adaptiveScore: Double
    var masteryLevel: MasteryLevel

    init(
        difficulty: Difficulty,
        correctAnswers: Int = 0,
        totalAnswers: Int = 0,
        adaptiveScore: Double = 0,
        masteryLevel: MasteryLevel = .novice
    ) {
        self.difficulty = difficulty
        self.correctAnswers = correctAnswers
        self.totalAnswers = totalAnswers
        self.adaptiveScore = adaptiveScore
        self.masteryLevel = masteryLevel
    }
}

// MARK: - Topic Progress
struct TopicProgress: Codable, Equatable, Identifiable {
    var id: String { topicId }
    var topicId: String
    var displayName: String?
    var correctAnswers: Int
    var totalAnswers: Int
    var masteryLevel: MasteryLevel
    var streak: Int
    var recommendedDifficulty: Difficulty?
    var lastActivityAt: Date?

    init(
        topicId: String,
        displayName: String? = nil,
        correctAnswers: Int = 0,
        totalAnswers: Int = 0,
        masteryLevel: MasteryLevel = .novice,
        streak: Int = 0,
        recommendedDifficulty: Difficulty? = nil,
        lastActivityAt: Date? = nil
    ) {
        self.topicId = topicId
        self.displayName = displayName
        self.correctAnswers = correctAnswers
        self.totalAnswers = totalAnswers
        self.masteryLevel = masteryLevel
        self.streak = streak
        self.recommendedDifficulty = recommendedDifficulty
        self.lastActivityAt = lastActivityAt
    }
}

// MARK: - Recommendation
struct LearningRecommendation: Codable, Equatable, Identifiable {
    enum RecommendationType: String, Codable {
        case focusTopic
        case increaseDifficulty
        case repeatMistakes
        case maintainStreak
    }

    var id: UUID
    var type: RecommendationType
    var title: String
    var message: String
    var topicId: String?
    var targetDifficulty: Difficulty?
    var createdAt: Date
    var expiresAt: Date?

    init(
        id: UUID = UUID(),
        type: RecommendationType,
        title: String,
        message: String,
        topicId: String? = nil,
        targetDifficulty: Difficulty? = nil,
        createdAt: Date = Date(),
        expiresAt: Date? = Calendar.current.date(byAdding: .day, value: 7, to: Date())
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.topicId = topicId
        self.targetDifficulty = targetDifficulty
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}

// MARK: - Mastery Level
enum MasteryLevel: String, Codable, CaseIterable {
    case novice
    case learning
    case proficient
    case expert

    var localizedTitle: String {
        switch self {
        case .novice:
            return "profile.mastery.novice".localized
        case .learning:
            return "profile.mastery.learning".localized
        case .proficient:
            return "profile.mastery.proficient".localized
        case .expert:
            return "profile.mastery.expert".localized
        }
    }
}

// MARK: - History Entries
struct QuizHistoryEntry: Codable, Equatable, Identifiable {
    var id: UUID
    var date: Date
    var percentage: Double
    var correctAnswers: Int
    var totalQuestions: Int
    var difficultyBreakdown: [String: Int]
    var topicBreakdown: [String: Int]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        percentage: Double,
        correctAnswers: Int,
        totalQuestions: Int,
        difficultyBreakdown: [String: Int],
        topicBreakdown: [String: Int]
    ) {
        self.id = id
        self.date = date
        self.percentage = percentage
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        self.difficultyBreakdown = difficultyBreakdown
        self.topicBreakdown = topicBreakdown
    }
}

struct ExamHistoryEntry: Codable, Equatable, Identifiable {
    var id: UUID
    var date: Date
    var percentage: Double
    var duration: TimeInterval
    var correctAnswers: Int
    var totalQuestions: Int
    var passed: Bool
    var configuration: ExamConfigurationSnapshot

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        percentage: Double,
        duration: TimeInterval,
        correctAnswers: Int,
        totalQuestions: Int,
        passed: Bool,
        configuration: ExamConfigurationSnapshot
    ) {
        self.id = id
        self.date = date
        self.percentage = percentage
        self.duration = duration
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        self.passed = passed
        self.configuration = configuration
    }
}

// MARK: - Exam Configuration Snapshot
struct ExamConfigurationSnapshot: Codable, Equatable {
    var totalQuestions: Int
    var timePerQuestion: TimeInterval
    var allowSkip: Bool
    /// Настройка удалена из приложения; поле сохраняется, чтобы профиль читался старыми версиями
    var autoSubmit: Bool
    var passingThreshold: Double

    init(configuration: ExamConfiguration, passingThreshold: Double = 70) {
        self.totalQuestions = configuration.totalQuestions
        self.timePerQuestion = configuration.timePerQuestion
        self.allowSkip = configuration.allowSkip
        self.autoSubmit = true
        self.passingThreshold = passingThreshold
    }
}

// MARK: - Helpers
enum ProfileMergeStrategy {
    case preferLocal
    case preferRemote
    case newest
}

struct ProfileMergeContext {
    var strategy: ProfileMergeStrategy
    var localUpdatedAt: Date?
    var remoteUpdatedAt: Date?
}

// MARK: - Device Identifier
enum UIDeviceIdentifierProvider {
    static func currentIdentifier() -> String? {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString
        #else
        return nil
        #endif
    }
}


// MARK: - Decoding
// Профиль — это и локальный файл, и запись в iCloud. Каждое поле читается отдельно,
// массивы — поэлементно: новое поле или нечитаемая запись истории не теряют весь профиль
// (см. StoredDataDecoding.swift). Обязательны только поля, без которых запись не имеет смысла.

extension UserProfile {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        authMethod = container.decode(.authMethod, default: .anonymous)
        fullName = container.decodeOptional(.fullName)
        customDisplayName = container.decodeOptional(.customDisplayName)
        localeIdentifier = container.decode(.localeIdentifier, default: Locale.current.identifier)
        avatarURL = container.decodeOptional(.avatarURL)
        progress = container.decode(.progress, default: ProfileProgress())
        preferences = container.decode(.preferences, default: ProfilePreferences())
        metadata = container.decode(.metadata, default: Metadata(createdAt: .distantPast, updatedAt: .distantPast))
    }
}

extension UserProfile.Metadata {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        createdAt = container.decode(.createdAt, default: .distantPast)
        // Без даты изменения запись проигрывает при выборе более новой
        updatedAt = container.decode(.updatedAt, default: .distantPast)
        lastSyncedAt = container.decodeOptional(.lastSyncedAt)
        lastDeviceIdentifier = container.decodeOptional(.lastDeviceIdentifier)
    }
}

extension ProfilePreferences {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ProfilePreferences()
        preferredDifficulty = container.decodeOptional(.preferredDifficulty)
        dailyGoal = container.decode(.dailyGoal, default: defaults.dailyGoal)
        notificationsEnabled = container.decode(.notificationsEnabled, default: defaults.notificationsEnabled)
        syncedSettings = container.decode(.syncedSettings, default: defaults.syncedSettings)
        preferredStudyTopics = container.decode(.preferredStudyTopics, default: defaults.preferredStudyTopics)
    }
}

extension DifficultyPerformance {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Неизвестная сложность — запись пропускается
        difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
        correctAnswers = container.decode(.correctAnswers, default: 0)
        totalAnswers = container.decode(.totalAnswers, default: 0)
        adaptiveScore = container.decode(.adaptiveScore, default: 0)
        masteryLevel = container.decode(.masteryLevel, default: .novice)
    }
}

extension TopicProgress {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        topicId = try container.decode(String.self, forKey: .topicId)
        displayName = container.decodeOptional(.displayName)
        correctAnswers = container.decode(.correctAnswers, default: 0)
        totalAnswers = container.decode(.totalAnswers, default: 0)
        masteryLevel = container.decode(.masteryLevel, default: .novice)
        streak = container.decode(.streak, default: 0)
        recommendedDifficulty = container.decodeOptional(.recommendedDifficulty)
        lastActivityAt = container.decodeOptional(.lastActivityAt)
    }
}

extension LearningRecommendation {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        // Неизвестный тип рекомендации — запись пропускается
        type = try container.decode(RecommendationType.self, forKey: .type)
        title = container.decode(.title, default: "")
        message = container.decode(.message, default: "")
        topicId = container.decodeOptional(.topicId)
        targetDifficulty = container.decodeOptional(.targetDifficulty)
        createdAt = container.decode(.createdAt, default: .distantPast)
        expiresAt = container.decodeOptional(.expiresAt)
    }
}

extension QuizHistoryEntry {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // id и дата обязательны: по ним записи объединяются и сортируются
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        percentage = container.decode(.percentage, default: 0)
        correctAnswers = container.decode(.correctAnswers, default: 0)
        totalQuestions = container.decode(.totalQuestions, default: 0)
        difficultyBreakdown = container.decode(.difficultyBreakdown, default: [:])
        topicBreakdown = container.decode(.topicBreakdown, default: [:])
    }
}

extension ExamHistoryEntry {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // id и дата обязательны: по ним записи объединяются и сортируются
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        percentage = container.decode(.percentage, default: 0)
        duration = container.decode(.duration, default: 0)
        correctAnswers = container.decode(.correctAnswers, default: 0)
        totalQuestions = container.decode(.totalQuestions, default: 0)
        passed = container.decode(.passed, default: false)
        configuration = container.decode(.configuration, default: ExamConfigurationSnapshot(configuration: .default))
    }
}

extension ExamConfigurationSnapshot {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ExamConfigurationSnapshot(configuration: .default)
        totalQuestions = container.decode(.totalQuestions, default: defaults.totalQuestions)
        timePerQuestion = container.decode(.timePerQuestion, default: defaults.timePerQuestion)
        allowSkip = container.decode(.allowSkip, default: defaults.allowSkip)
        autoSubmit = container.decode(.autoSubmit, default: defaults.autoSubmit)
        passingThreshold = container.decode(.passingThreshold, default: defaults.passingThreshold)
    }
}
