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
    
    /// `dayStreak` — серия дней с занятиями на сегодня (StatsManager.dayStreak)
    func checkAchievements(for stats: UserStats, dayStreak: Int, quizResult: QuizResult? = nil) {
        var newlyUnlocked: [Achievement] = []
        
        for achievementType in AchievementType.allCases {
            if let achievement = achievements.first(where: { $0.type == achievementType && !$0.isUnlocked }) {
                if shouldUnlockAchievement(achievement, stats: stats, dayStreak: dayStreak, quizResult: quizResult) {
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
    
    func getAchievementProgress(for type: AchievementType, stats: UserStats, dayStreak: Int) -> AchievementProgress {
        let requirement = getRequirement(for: type)
        let currentProgress = getCurrentProgress(for: type, stats: stats, dayStreak: dayStreak)
        
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
    
    private func createDefaultAchievements() -> [Achievement] {
        return [
            Achievement(
                id: "first_quiz",
                title: AchievementType.firstQuiz.title(using: localizationProvider),
                description: AchievementType.firstQuiz.description(using: localizationProvider),
                icon: "play.circle.fill",
                color: .blue,
                type: .firstQuiz,
                requirement: 1
            ),
            Achievement(
                id: "perfect_score",
                title: AchievementType.perfectScore.title(using: localizationProvider),
                description: AchievementType.perfectScore.description(using: localizationProvider),
                icon: "star.fill",
                color: .yellow,
                type: .perfectScore,
                requirement: 1
            ),
            Achievement(
                id: "speed_runner",
                title: AchievementType.speedRunner.title(using: localizationProvider),
                description: AchievementType.speedRunner.description(using: localizationProvider),
                icon: "timer",
                color: .orange,
                type: .speedRunner,
                requirement: 1
            ),
            Achievement(
                id: "scholar",
                title: AchievementType.scholar.title(using: localizationProvider),
                description: AchievementType.scholar.description(using: localizationProvider),
                icon: "book.fill",
                color: .purple,
                type: .scholar,
                requirement: 100
            ),
            Achievement(
                id: "dedicated",
                title: AchievementType.dedicated.title(using: localizationProvider),
                description: AchievementType.dedicated.description(using: localizationProvider),
                icon: "flame.fill",
                color: .red,
                type: .dedicated,
                requirement: 10
            ),
            Achievement(
                id: "master",
                title: AchievementType.master.title(using: localizationProvider),
                description: AchievementType.master.description(using: localizationProvider),
                icon: "crown.fill",
                color: .yellow,
                type: .master,
                requirement: 50
            ),
            Achievement(
                id: "streak",
                title: AchievementType.streak.title(using: localizationProvider),
                description: AchievementType.streak.description(using: localizationProvider),
                icon: "bolt.fill",
                color: .cyan,
                type: .streak,
                requirement: 5
            ),
            Achievement(
                id: "explorer",
                title: AchievementType.explorer.title(using: localizationProvider),
                description: AchievementType.explorer.description(using: localizationProvider),
                icon: "globe",
                color: .green,
                type: .explorer,
                requirement: 500
            ),
            Achievement(
                id: "perfectionist",
                title: AchievementType.perfectionist.title(using: localizationProvider),
                description: AchievementType.perfectionist.description(using: localizationProvider),
                icon: "diamond.fill",
                color: .pink,
                type: .perfectionist,
                requirement: 10
            ),
            Achievement(
                id: "legend",
                title: AchievementType.legend.title(using: localizationProvider),
                description: AchievementType.legend.description(using: localizationProvider),
                icon: "trophy.fill",
                color: .indigo,
                type: .legend,
                requirement: 100
            )
        ]
    }
    
    private func shouldUnlockAchievement(_ achievement: Achievement, stats: UserStats, dayStreak: Int, quizResult: QuizResult?) -> Bool {
        switch achievement.type {
        case .firstQuiz:
            return stats.totalQuizzesCompleted >= 1
        case .perfectScore:
            // Используем >= 99.99 для учета погрешности округления при расчете процента
            return (quizResult?.percentage ?? 0) >= 99.99
        case .speedRunner:
            // Проверяем, что викторина завершена менее чем за 2 минуты И с минимум 80% правильных ответов
            guard let result = quizResult else { return false }
            return result.timeSpent < 120 && result.percentage >= 80.0
        case .scholar:
            return stats.totalQuestionsStudied >= 100
        case .dedicated:
            return stats.totalQuizzesCompleted >= 10
        case .master:
            return stats.totalQuizzesCompleted >= 50
        case .streak:
            // Серия дней с занятиями, как на главном экране
            return dayStreak >= 5
        case .explorer:
            return stats.totalQuestionsStudied >= 500
        case .perfectionist:
            return stats.perfectScores >= 10
        case .legend:
            return stats.totalQuizzesCompleted >= 100
        }
    }
    
    private func getRequirement(for type: AchievementType) -> Int {
        switch type {
        case .firstQuiz, .perfectScore, .speedRunner:
            return 1
        case .scholar:
            return 100
        case .dedicated:
            return 10
        case .master:
            return 50
        case .streak:
            return 5
        case .explorer:
            return 500
        case .perfectionist:
            return 10
        case .legend:
            return 100
        }
    }
    
    private func getCurrentProgress(for type: AchievementType, stats: UserStats, dayStreak: Int) -> Int {
        switch type {
        case .firstQuiz, .perfectScore, .speedRunner:
            return 0 // These are checked differently
        case .scholar, .explorer:
            return stats.totalQuestionsStudied
        case .dedicated, .master, .legend:
            return stats.totalQuizzesCompleted
        case .streak:
            return dayStreak
        case .perfectionist:
            return stats.perfectScores
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
