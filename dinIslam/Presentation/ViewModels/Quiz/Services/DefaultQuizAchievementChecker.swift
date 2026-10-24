//
//  DefaultQuizAchievementChecker.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

final class DefaultQuizAchievementChecker: QuizAchievementChecking {
    private let achievementManager: AchievementManager
    
    var newAchievements: [Achievement] {
        achievementManager.newAchievements
    }
    
    init(achievementManager: AchievementManager) {
        self.achievementManager = achievementManager
    }
    
    func checkAchievements(for stats: UserStats, dayStreak: Int, quizResult: QuizResult?) {
        achievementManager.checkAchievements(for: stats, dayStreak: dayStreak, quizResult: quizResult)
    }
    
    func clearNewAchievements() {
        achievementManager.clearNewAchievements()
    }
}

