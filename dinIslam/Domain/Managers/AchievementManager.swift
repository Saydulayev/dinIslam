//
//  AchievementManager.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Observation
import SwiftUI

@Observable
class AchievementManager: AchievementManaging {
    var achievements: [Achievement] = []
    var newAchievements: [Achievement] = []
    
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let achievementsKey = "UserAchievements"
    @ObservationIgnored private let notificationManager: NotificationManager
    @ObservationIgnored private let localizationProvider: LocalizationProviding
    
    init(
        userDefaults: UserDefaults = .standard,
        notificationManager: NotificationManager,
        localizationProvider: LocalizationProviding? = nil
    ) {
        self.userDefaults = userDefaults
        self.notificationManager = notificationManager
        // Use provided localization provider or create default for backward compatibility
        self.localizationProvider = localizationProvider ?? LocalizationManager()
        loadAchievements()
    }
    
    func refreshLocalization() {
        // Update achievement titles and descriptions when language changes
        for i in 0..<achievements.count {
            achievements[i] = Achievement(
                id: achievements[i].id,
                title: achievements[i].type.title(using: localizationProvider),
                description: achievements[i].type.description(using: localizationProvider),
                icon: achievements[i].icon,
                color: achievements[i].color,
                type: achievements[i].type,
                requirement: achievements[i].requirement,
                isUnlocked: achievements[i].isUnlocked,
                unlockedDate: achievements[i].unlockedDate
            )
        }
        saveAchievements()
    }
    
    // MARK: - Public Methods
    
    func checkAchievements(_ context: AchievementContext, quizResult: QuizResult? = nil) {
        var newlyUnlocked: [Achievement] = []
        
        for achievementType in AchievementType.allCases {
            if let achievement = achievements.first(where: { $0.type == achievementType && !$0.isUnlocked }) {
                if shouldUnlockAchievement(achievement, context: context, quizResult: quizResult) {
                    let unlockedAchievement = Achievement(
                        id: achievement.id,
                        title: achievement.title,
                        description: achievement.description,
                        icon: achievement.icon,
                        color: achievement.color,
                        type: achievement.type,
                        requirement: achievement.requirement,
                        isUnlocked: true,
                        unlockedDate: Date()
                    )
                    
                    // Update in achievements array
                    if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
                        achievements[index] = unlockedAchievement
                    }
                    
                    newlyUnlocked.append(unlockedAchievement)
                }
            }
        }
        
        if !newlyUnlocked.isEmpty {
            newAchievements = newlyUnlocked
            saveAchievements()
            SyncedDataChange.post()
            
            // Schedule notification for each new achievement
            for achievement in newlyUnlocked {
                notificationManager.scheduleAchievementNotification(for: achievement)
            }
        }
    }
    
    /// nil — прогресс не известен (размер банка ещё не загружен)
    func getAchievementProgress(for type: AchievementType, context: AchievementContext) -> AchievementProgress? {
        guard let requirement = getRequirement(for: type, bankProgress: context.bankProgress),
              let currentProgress = getCurrentProgress(for: type, context: context) else {
            return nil
        }
        
        return AchievementProgress(
            achievementType: type,
            currentProgress: currentProgress,
            requirement: requirement,
            isCompleted: currentProgress >= requirement
        )
    }
    
    func clearNewAchievements() {
        newAchievements.removeAll()
    }
    
    func resetAllAchievements() {
        // Reset all achievements to locked state
        for i in 0..<achievements.count {
            achievements[i] = Achievement(
                id: achievements[i].id,
                title: achievements[i].title,
                description: achievements[i].description,
                icon: achievements[i].icon,
                color: achievements[i].color,
                type: achievements[i].type,
                requirement: achievements[i].requirement,
                isUnlocked: false,
                unlockedDate: nil
            )
        }
        
        // Clear new achievements
        newAchievements.removeAll()
        
        // Save changes
        saveAchievements()
        SyncedDataChange.post(resetSections: [.achievements])
    }
    
    // MARK: - Sync
    
    /// Открытые достижения: id → дата открытия
    var unlockedDates: [String: Date] {
        Dictionary(
            achievements.filter(\.isUnlocked).map { ($0.id, $0.unlockedDate ?? .distantPast) },
            uniquingKeysWith: { first, _ in first }
        )
    }
    
    /// Открытые достижения из iCloud: записываются без уведомления о локальном изменении
    func applyUnlockedDates(_ unlocked: [String: Date]) {
        guard unlocked != unlockedDates else { return }
        achievements = achievements.map { achievement in
            let unlockedDate = unlocked[achievement.id]
            return Achievement(
                id: achievement.id,
                title: achievement.title,
                description: achievement.description,
                icon: achievement.icon,
                color: achievement.color,
                type: achievement.type,
                requirement: achievement.requirement,
                isUnlocked: unlockedDate != nil,
                unlockedDate: unlockedDate
            )
        }
        saveAchievements()
    }
    
    // MARK: - Private Methods
    
    /// Порядок — как в списке на экране. `requirement` для «Ищущего знания» и «Мудрого» — 0:
    /// их требование зависит от размера банка и считается в getRequirement
    private func createDefaultAchievements() -> [Achievement] {
        let definitions: [(type: AchievementType, icon: String, color: Color, requirement: Int)] = [
            (.firstQuiz, "play.circle.fill", .blue, 1),
            (.examPassed, "graduationcap.fill", .purple, 1),
            (.perfectScore, "star.fill", .yellow, 1),
            (.speedRunner, "timer", .orange, 1),
            (.scholar, "book.fill", .purple, 100),
            (.dedicated, "flame.fill", .red, 10),
            (.streak, "bolt.fill", .cyan, 5),
            (.streakWeek, "calendar", .orange, 7),
            (.streakMonth, "calendar.badge.checkmark", .red, 30),
            (.mistakesLearned, "arrow.triangle.2.circlepath", .green, 10),
            (.mistakesMastered, "checkmark.seal.fill", .cyan, 50),
            (.explorer, "globe", .green, 500),
            (.perfectionist, "diamond.fill", .pink, 10),
            (.master, "crown.fill", .yellow, 0),
            (.legend, "trophy.fill", .indigo, 0)
        ]
        return definitions.map { definition in
            Achievement(
                id: definition.type.rawValue,
                title: definition.type.title(using: localizationProvider),
                description: definition.type.description(using: localizationProvider),
                icon: definition.icon,
                color: definition.color,
                type: definition.type,
                requirement: definition.requirement
            )
        }
    }
    
    private func shouldUnlockAchievement(_ achievement: Achievement, context: AchievementContext, quizResult: QuizResult?) -> Bool {
        switch achievement.type {
        case .perfectScore:
            // Используем >= 99.99 для учета погрешности округления при расчете процента
            return (quizResult?.percentage ?? 0) >= 99.99
        case .speedRunner:
            // Проверяем, что викторина завершена менее чем за 2 минуты И с минимум 80% правильных ответов
            guard let result = quizResult else { return false }
            return result.timeSpent < 120 && result.percentage >= 80.0
        default:
            guard let requirement = getRequirement(for: achievement.type, bankProgress: context.bankProgress),
                  let progress = getCurrentProgress(for: achievement.type, context: context),
                  requirement > 0 else {
                return false
            }
            return progress >= requirement
        }
    }
    
    /// Требование: «Ищущий знания» — половина банка, «Мудрый» — весь банк
    private func getRequirement(for type: AchievementType, bankProgress: BankProgress?) -> Int? {
        switch type {
        case .firstQuiz, .examPassed, .perfectScore, .speedRunner:
            return 1
        case .scholar:
            return 100
        case .dedicated:
            return 10
        case .streak:
            return 5
        case .streakWeek:
            return 7
        case .streakMonth:
            return 30
        case .mistakesLearned:
            return 10
        case .mistakesMastered:
            return 50
        case .explorer:
            return 500
        case .perfectionist:
            return 10
        case .master:
            return bankProgress.map { ($0.total + 1) / 2 }
        case .legend:
            return bankProgress?.total
        }
    }
    
    private func getCurrentProgress(for type: AchievementType, context: AchievementContext) -> Int? {
        let stats = context.stats
        switch type {
        case .perfectScore, .speedRunner:
            return 0 // These are checked differently
        case .firstQuiz, .dedicated:
            return stats.totalQuizzesCompleted
        case .examPassed:
            return context.examsPassed
        case .scholar, .explorer:
            return stats.totalQuestionsStudied
        case .streak, .streakWeek, .streakMonth:
            // Серия дней с занятиями, как на главном экране
            return context.dayStreak
        case .mistakesLearned, .mistakesMastered:
            // Ошибки, прошедшие все этапы повторения
            return stats.correctedMistakes
        case .perfectionist:
            return stats.perfectScores
        case .master, .legend:
            return context.bankProgress?.studied
        }
    }
    
    private func saveAchievements() {
        let codableAchievements = achievements.map { CodableAchievement(from: $0) }
        if let encoded = try? JSONEncoder().encode(codableAchievements) {
            userDefaults.set(encoded, forKey: achievementsKey)
        }
    }
    
    /// Список достижений берётся из приложения, из сохранённых данных — только что открыто и когда.
    /// Так новые достижения и изменённые требования доходят до тех, у кого данные уже сохранены,
    /// а нечитаемая запись теряет одно достижение, а не все.
    private func loadAchievements() {
        let stored = userDefaults.decodeStored([LossyDecodable<CodableAchievement>].self, forKey: achievementsKey)?
            .compactMap(\.value) ?? []
        let unlockedById = Dictionary(
            stored.filter(\.isUnlocked).map { ($0.id, $0.unlockedDate) },
            uniquingKeysWith: { first, _ in first }
        )

        achievements = createDefaultAchievements().map { achievement in
            guard let unlockedDate = unlockedById[achievement.id] else { return achievement }
            return Achievement(
                id: achievement.id,
                title: achievement.title,
                description: achievement.description,
                icon: achievement.icon,
                color: achievement.color,
                type: achievement.type,
                requirement: achievement.requirement,
                isUnlocked: true,
                unlockedDate: unlockedDate
            )
        }

        if stored.isEmpty {
            saveAchievements()
        }
    }
}
