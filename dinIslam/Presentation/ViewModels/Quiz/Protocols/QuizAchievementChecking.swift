//
//  QuizAchievementChecking.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

protocol QuizAchievementChecking {
    var newAchievements: [Achievement] { get }
    
    func checkAchievements(_ context: AchievementContext, quizResult: QuizResult?)
    func clearNewAchievements()
}

