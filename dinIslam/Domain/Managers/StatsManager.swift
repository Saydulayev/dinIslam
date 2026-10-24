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
    /// Меняется при возврате в приложение и смене дня: так экран пересчитывает значения,
    /// зависящие от текущей даты (серия, цель дня, повторение)
    private var dateRevision = 0
    
    init(
        userDefaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init
    ) {
        self.userDefaults = userDefaults
        self.now = now
        self.stats = Self.load(UserStats.self, from: userDefaults, key: statsKey) ?? UserStats()
        self.reviewSchedule = Self.load(ReviewSchedule.self, from: userDefaults, key: reviewScheduleKey) ?? ReviewSchedule()
        self.dailyProgress = Self.load(DailyProgress.self, from: userDefaults, key: dailyProgressKey) ?? DailyProgress()
        
        // Ошибки, накопленные до появления расписания, доступны для повторения сразу
        reviewSchedule.sync(with: stats.wrongQuestionIds, now: self.now())
        saveReviewSchedule()
    }
    
    private static func load<T: Decodable>(_ type: T.Type, from userDefaults: UserDefaults, key: String) -> T? {
        userDefaults.decodeStored(type, forKey: key)
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
        SyncedDataChange.post()
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
        SyncedDataChange.post()
        return summary
    }
    
    func registerDailyGoal() {
        dailyProgress.registerDailyGoal(at: now())
        saveDailyProgress()
        SyncedDataChange.post()
    }
    
    func clearWrongQuestions() {
        stats.clearWrongQuestions()
        reviewSchedule.removeAll()
        saveStats()
        saveReviewSchedule()
        SyncedDataChange.post()
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
        reviewSchedule.dueCount(at: currentDate())
    }
    
    /// Сколько ошибок будет к повторению на указанный момент (для напоминаний)
    func dueReviewCount(at date: Date) -> Int {
        reviewSchedule.dueCount(at: date)
    }
    
    var nextReviewDate: Date? {
        reviewSchedule.nextDueDate(after: currentDate())
    }
    
    var dayStreak: Int {
        dailyProgress.streak(at: currentDate())
    }
    
    var isDailyGoalCompletedToday: Bool {
        dailyProgress.isDailyGoalCompleted(on: currentDate())
    }
    
    var isActiveToday: Bool {
        dailyProgress.isActive(on: currentDate())
    }
    
    /// Пересчитать на экране значения, зависящие от текущей даты
    func refreshCurrentDate() {
        dateRevision += 1
    }
    
    /// Чтение `dateRevision` подписывает экран на `refreshCurrentDate()`
    private func currentDate() -> Date {
        _ = dateRevision
        return now()
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
        SyncedDataChange.post(resetSections: [.stats, .achievementProgress])
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
        stats.perfectScores = 0
        saveStats()
        SyncedDataChange.post(resetSections: [.achievementProgress])
    }
    
    // MARK: - Sync
    /// Данные из iCloud: записываются без уведомления о локальном изменении
    func applySyncedState(stats: UserStats, reviewSchedule: ReviewSchedule, dailyProgress: DailyProgress) {
        self.stats = stats
        self.reviewSchedule = reviewSchedule
        self.dailyProgress = dailyProgress
        saveStats()
        saveReviewSchedule()
        saveDailyProgress()
    }
}

// MARK: - DailyReminderContextProviding
extension StatsManager: DailyReminderContextProviding {}

// MARK: - TopicStatsProviding
extension StatsManager: TopicStatsProviding {
    var topicStats: [String: TopicStat] {
        stats.topicStats
    }
}
