//
//  StatsManager.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Observation

@MainActor
@Observable
class StatsManager {
    private var profileProgressSyncer: ProfileProgressSyncing?
    var stats: UserStats
    /// Когда повторять каждую ошибку (хранится локально, как и список ошибок)
    private(set) var reviewSchedule: ReviewSchedule
    /// Серия дней с занятиями и ежедневная цель
    private(set) var dailyProgress: DailyProgress
    
    private let userDefaults: UserDefaults
    private let statsKey = "UserStats"
    private let reviewScheduleKey = "MistakeReviewSchedule"
    private let dailyProgressKey = "DailyProgress"
    private let now: () -> Date
    
    init(
        userDefaults: UserDefaults = .standard,
        profileProgressSyncer: ProfileProgressSyncing? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.userDefaults = userDefaults
        self.profileProgressSyncer = profileProgressSyncer
        self.now = now
        self.stats = Self.load(UserStats.self, from: userDefaults, key: statsKey) ?? UserStats()
        self.reviewSchedule = Self.load(ReviewSchedule.self, from: userDefaults, key: reviewScheduleKey) ?? ReviewSchedule()
        self.dailyProgress = Self.load(DailyProgress.self, from: userDefaults, key: dailyProgressKey) ?? DailyProgress()
        
        // Ошибки, накопленные до появления расписания, доступны для повторения сразу
        reviewSchedule.sync(with: stats.wrongQuestionIds, now: self.now())
        saveReviewSchedule()
    }
    
    func setProfileProgressSyncer(_ syncer: ProfileProgressSyncing?) {
        self.profileProgressSyncer = syncer
    }
    
    private static func load<T: Decodable>(_ type: T.Type, from userDefaults: UserDefaults, key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func recordQuizSession(_ summary: QuizSessionSummary) {
        stats.recordQuizSession(summary)
        
        // Вопросы из повторения могут попасться и в обычной викторине (режим повторения банка)
        for outcome in summary.outcomes {
            if outcome.isCorrect {
                if reviewSchedule.recordAnswer(outcome.questionId, isCorrect: true, at: summary.completedAt) == .graduated {
                    stats.removeWrongQuestion(outcome.questionId)
                }
            } else {
                reviewSchedule.registerMistake(outcome.questionId, at: summary.completedAt)
            }
        }
        dailyProgress.registerActivity(at: summary.completedAt)
        
        saveStats()
        saveReviewSchedule()
        saveDailyProgress()
        profileProgressSyncer?.syncStatsUpdate(summary)
    }
    
    /// Итог повторения ошибок: правильные ответы в срок продвигают вопрос по расписанию,
    /// ошибки возвращают его к началу. Выученные вопросы убираются из списка ошибок.
    @discardableResult
    func recordReviewAnswers(_ answers: [String: Bool]) -> ReviewSessionSummary {
        let date = now()
        var summary = ReviewSessionSummary()
        
        for (questionId, isCorrect) in answers {
            if !reviewSchedule.isTracked(questionId) && !isCorrect {
                reviewSchedule.registerMistake(questionId, at: date)
                stats.wrongQuestionIds.insert(questionId)
                summary.reset += 1
                continue
            }
            
            switch reviewSchedule.recordAnswer(questionId, isCorrect: isCorrect, at: date) {
            case .graduated:
                stats.removeWrongQuestion(questionId)
                summary.graduated += 1
            case .advanced:
                summary.advanced += 1
            case .reset:
                stats.wrongQuestionIds.insert(questionId)
                summary.reset += 1
            case .notDue:
                summary.notDue += 1
            case .notTracked:
                break
            }
        }
        
        summary.remaining = reviewSchedule.count
        summary.nextDueDate = reviewSchedule.nextDueDate(after: date)
        
        if !answers.isEmpty {
            dailyProgress.registerActivity(at: date)
        }
        
        saveStats()
        saveReviewSchedule()
        saveDailyProgress()
        // Уведомляем syncer об обновлении статистики для синхронизации с ProfileManager
        profileProgressSyncer?.syncStatsDidUpdate()
        return summary
    }
    
    func registerDailyGoal() {
        dailyProgress.registerDailyGoal(at: now())
        saveDailyProgress()
    }
    
    func clearWrongQuestions() {
        stats.clearWrongQuestions()
        reviewSchedule.removeAll()
        saveStats()
        saveReviewSchedule()
    }
    
    func getWrongQuestions(from allQuestions: [Question]) -> [Question] {
        return allQuestions.filter { stats.wrongQuestionIds.contains($0.id) }
    }
    
    /// Ошибки, срок повторения которых наступил
    func getDueWrongQuestions(from allQuestions: [Question]) -> [Question] {
        let dueIds = reviewSchedule.dueIds(at: now())
        return allQuestions.filter { dueIds.contains($0.id) && stats.wrongQuestionIds.contains($0.id) }
    }
    
    // MARK: - Review & Daily Progress
    
    var dueReviewCount: Int {
        reviewSchedule.dueCount(at: now())
    }
    
    var nextReviewDate: Date? {
        reviewSchedule.nextDueDate(after: now())
    }
    
    var dayStreak: Int {
        dailyProgress.streak(at: now())
    }
    
    var isDailyGoalCompletedToday: Bool {
        dailyProgress.isDailyGoalCompleted(on: now())
    }
    
    var isActiveToday: Bool {
        dailyProgress.isActive(on: now())
    }

    private func saveStats() {
        save(stats, key: statsKey)
    }
    
    private func saveReviewSchedule() {
        save(reviewSchedule, key: reviewScheduleKey)
    }
    
    private func saveDailyProgress() {
        save(dailyProgress, key: dailyProgressKey)
    }
    
    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    func resetStats() {
        stats = UserStats()
        reviewSchedule.removeAll()
        dailyProgress = DailyProgress()
        saveStats()
        saveReviewSchedule()
        saveDailyProgress()
        profileProgressSyncer?.syncStatsReset()
    }
    
    func resetStatsExceptTotalQuestions() {
        resetStats()
    }
    
    func getCorrectedMistakesCount() -> Int {
        return stats.correctedMistakes
    }
    
    // MARK: - Recent Score Methods
    
    func getAverageRecentScore() -> Double {
        return stats.averageRecentScore
    }
    
    func getRecentGamesCount() -> Int {
        return stats.recentGamesCount
    }
    
    func hasRecentGames() -> Bool {
        return !stats.recentQuizResults.isEmpty
    }

    // MARK: - Achievements-related reset
    func resetAchievementProgress() {
        // Сбрасываем только метрики, влияющие на прогресс достижений
        stats.totalQuestionsStudied = 0
        stats.totalQuizzesCompleted = 0
        stats.currentStreak = 0
        stats.perfectScores = 0
        stats.longestStreak = 0
        saveStats()
        profileProgressSyncer?.syncStatsReset()
    }
    
    // MARK: - Profile Progress Sync
    func updateFromProfileProgress(_ progress: ProfileProgress, quizHistory: [QuizHistoryEntry]) {
        // Сохраняем wrongQuestionIds, чтобы не потерять их при обновлении
        let preservedWrongQuestionIds = stats.wrongQuestionIds
        
        // Обновляем основные метрики
        stats.totalQuestionsStudied = progress.totalQuestionsAnswered
        stats.correctAnswers = progress.correctAnswers
        stats.incorrectAnswers = progress.incorrectAnswers
        stats.correctedMistakes = progress.correctedMistakes
        stats.currentStreak = progress.currentStreak
        stats.longestStreak = progress.longestStreak
        stats.lastActivityAt = progress.lastActivityAt
        stats.lastQuizDate = progress.lastActivityAt
        
        // Восстанавливаем wrongQuestionIds (они не синхронизируются с CloudKit, остаются локальными)
        stats.wrongQuestionIds = preservedWrongQuestionIds
        
        // Обновляем recentQuizResults из quizHistory
        stats.recentQuizResults = quizHistory.prefix(10).map { entry in
            QuizResultRecord(
                percentage: entry.percentage,
                date: entry.date,
                questionsCount: entry.totalQuestions
            )
        }
        
        // Обновляем topicStats из topicProgress
        stats.topicStats = Dictionary(uniqueKeysWithValues: progress.topicProgress.map { topic in
            (topic.topicId, TopicStat(
                correctAnswers: topic.correctAnswers,
                totalAnswers: topic.totalAnswers,
                streak: topic.streak,
                longestStreak: topic.streak, // Используем текущий streak как longest, так как в TopicProgress нет longestStreak
                lastUpdated: topic.lastActivityAt
            ))
        })
        
        // Обновляем difficultyStats из difficultyStats
        stats.difficultyStats = Dictionary(uniqueKeysWithValues: progress.difficultyStats.map { difficulty in
            (difficulty.difficulty.rawValue, DifficultyStat(
                correctAnswers: difficulty.correctAnswers,
                totalAnswers: difficulty.totalAnswers,
                adaptiveScore: difficulty.adaptiveScore,
                lastUpdated: nil // В DifficultyPerformance нет lastUpdated
            ))
        })
        
        // Вычисляем totalQuizzesCompleted из quizHistory
        stats.totalQuizzesCompleted = quizHistory.count
        
        // averageRecentScore вычисляется автоматически через computed property в UserStats
        
        saveStats()
    }
}
