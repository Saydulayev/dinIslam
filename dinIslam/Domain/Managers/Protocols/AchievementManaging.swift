//
//  AchievementManaging.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

protocol AchievementManaging {
    var newAchievements: [Achievement] { get }
    var achievements: [Achievement] { get }
    
    func checkAchievements(for stats: UserStats, quizResult: QuizResult?)
    func clearNewAchievements()
    func refreshLocalization()
    func resetAllAchievements()
    func getAchievementProgress(for type: AchievementType, stats: UserStats) -> AchievementProgress
}

