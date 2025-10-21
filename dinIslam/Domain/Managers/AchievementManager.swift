//
//  AchievementManager.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Combine
import SwiftUI

class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var newAchievements: [Achievement] = []
    
    private let userDefaults = UserDefaults.standard
    private let achievementsKey = "UserAchievements"
    private let notificationManager = NotificationManager()
    
    init() {
        loadAchievements()
        initializeDefaultAchievements()
        
        // Listen for language changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageChanged,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func languageChanged() {
        // Update achievement titles and descriptions when language changes
        for i in 0..<achievements.count {
            achievements[i] = Achievement(
                id: achievements[i].id,
                title: achievements[i].type.localizedTitle,
                description: achievements[i].type.localizedDescription,
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
    
    func checkAchievements(for stats: UserStats, quizResult: QuizResult? = nil) {
        var newlyUnlocked: [Achievement] = []
        
        for achievementType in AchievementType.allCases {
            if let achievement = achievements.first(where: { $0.type == achievementType && !$0.isUnlocked }) {
                if shouldUnlockAchievement(achievement, stats: stats, quizResult: quizResult) {
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
            
            // Schedule notification for each new achievement
            for achievement in newlyUnlocked {
                notificationManager.scheduleAchievementNotification(for: achievement)
            }
        }
    }
    
    func getAchievementProgress(for type: AchievementType, stats: UserStats) -> AchievementProgress {
        let requirement = getRequirement(for: type)
        let currentProgress = getCurrentProgress(for: type, stats: stats)
        
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
    
    // MARK: - Private Methods
    
    private func initializeDefaultAchievements() {
        if achievements.isEmpty {
            achievements = createDefaultAchievements()
            saveAchievements()
        }
    }
    
    private func createDefaultAchievements() -> [Achievement] {
        return [
            Achievement(
                id: "first_quiz",
                title: AchievementType.firstQuiz.localizedTitle,
                description: AchievementType.firstQuiz.localizedDescription,
                icon: "play.circle.fill",
                color: .blue,
                type: .firstQuiz,
                requirement: 1
            ),
            Achievement(
                id: "perfect_score",
                title: AchievementType.perfectScore.localizedTitle,
                description: AchievementType.perfectScore.localizedDescription,
                icon: "star.fill",
                color: .yellow,
                type: .perfectScore,
                requirement: 1
            ),
            Achievement(
                id: "speed_runner",
                title: AchievementType.speedRunner.localizedTitle,
                description: AchievementType.speedRunner.localizedDescription,
                icon: "timer",
                color: .orange,
                type: .speedRunner,
                requirement: 1
            ),
            Achievement(
                id: "scholar",
                title: AchievementType.scholar.localizedTitle,
                description: AchievementType.scholar.localizedDescription,
                icon: "book.fill",
                color: .purple,
                type: .scholar,
                requirement: 100
            ),
            Achievement(
                id: "dedicated",
                title: AchievementType.dedicated.localizedTitle,
                description: AchievementType.dedicated.localizedDescription,
                icon: "flame.fill",
                color: .red,
                type: .dedicated,
                requirement: 10
            ),
            Achievement(
                id: "master",
                title: AchievementType.master.localizedTitle,
                description: AchievementType.master.localizedDescription,
                icon: "crown.fill",
                color: .yellow,
                type: .master,
                requirement: 50
            ),
            Achievement(
                id: "streak",
                title: AchievementType.streak.localizedTitle,
                description: AchievementType.streak.localizedDescription,
                icon: "bolt.fill",
                color: .cyan,
                type: .streak,
                requirement: 5
            ),
            Achievement(
                id: "explorer",
                title: AchievementType.explorer.localizedTitle,
                description: AchievementType.explorer.localizedDescription,
                icon: "globe",
                color: .green,
                type: .explorer,
                requirement: 500
            ),
            Achievement(
                id: "perfectionist",
                title: AchievementType.perfectionist.localizedTitle,
                description: AchievementType.perfectionist.localizedDescription,
                icon: "diamond.fill",
                color: .pink,
                type: .perfectionist,
                requirement: 10
            ),
            Achievement(
                id: "legend",
                title: AchievementType.legend.localizedTitle,
                description: AchievementType.legend.localizedDescription,
                icon: "trophy.fill",
                color: .indigo,
                type: .legend,
                requirement: 100
            )
        ]
    }
    
    private func shouldUnlockAchievement(_ achievement: Achievement, stats: UserStats, quizResult: QuizResult?) -> Bool {
        switch achievement.type {
        case .firstQuiz:
            return stats.totalQuizzesCompleted >= 1
        case .perfectScore:
            return quizResult?.percentage == 100.0
        case .speedRunner:
            return quizResult?.timeSpent ?? 0 < 120 // 2 minutes
        case .scholar:
            return stats.totalQuestionsStudied >= 100
        case .dedicated:
            return stats.totalQuizzesCompleted >= 10
        case .master:
            return stats.totalQuizzesCompleted >= 50
        case .streak:
            return stats.currentStreak >= 5
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
    
    private func getCurrentProgress(for type: AchievementType, stats: UserStats) -> Int {
        switch type {
        case .firstQuiz, .perfectScore, .speedRunner:
            return 0 // These are checked differently
        case .scholar, .explorer:
            return stats.totalQuestionsStudied
        case .dedicated, .master, .legend:
            return stats.totalQuizzesCompleted
        case .streak:
            return stats.currentStreak
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
    
    private func loadAchievements() {
        guard let data = userDefaults.data(forKey: achievementsKey),
              let loadedCodableAchievements = try? JSONDecoder().decode([CodableAchievement].self, from: data) else {
            return
        }
        achievements = loadedCodableAchievements.map { $0.toAchievement() }
    }
}
