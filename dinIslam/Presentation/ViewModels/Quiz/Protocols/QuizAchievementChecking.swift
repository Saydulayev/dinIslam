//
//  QuizAchievementChecking.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol QuizAchievementChecking {
    var newAchievements: [Achievement] { get }
    
    func checkAchievements(for stats: UserStats, quizResult: QuizResult?)
    func clearNewAchievements()
}

