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
    
    func checkAchievements(_ context: AchievementContext, quizResult: QuizResult?) {
        achievementManager.checkAchievements(context, quizResult: quizResult)
    }
    
    func clearNewAchievements() {
        achievementManager.clearNewAchievements()
    }
}

