//
//  DefaultQuizAchievementChecker.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
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
    
    func checkAchievements(for stats: UserStats, quizResult: QuizResult?) {
        achievementManager.checkAchievements(for: stats, quizResult: quizResult)
    }
    
    func clearNewAchievements() {
        achievementManager.clearNewAchievements()
    }
}

