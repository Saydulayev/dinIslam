//
//  DefaultStartNavigationCoordinator.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import SwiftUI

@MainActor
final class DefaultStartNavigationCoordinator: StartNavigationCoordinating {
    var navigationPath = NavigationPath()
    
    func showQuiz() {
        navigationPath.append(StartRoute.quiz)
    }
    
    func showResult(_ snapshot: StartRoute.ResultSnapshot) {
        navigationPath.append(StartRoute.result(snapshot))
    }
    
    func showAchievements() {
        navigationPath.append(StartRoute.achievements)
    }
    
    func showSettings() {
        navigationPath.append(StartRoute.settings)
    }
    
    func showProfile() {
        navigationPath.append(StartRoute.profile)
    }
    
    func showExam() {
        navigationPath.append(StartRoute.exam)
    }
    
    func resetNavigation() {
        navigationPath = NavigationPath()
    }
    
    func finishExamSession() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func showBankCompletion(totalQuestions: Int) {
        navigationPath.append(StartRoute.bankCompletion(totalQuestions: totalQuestions))
    }
}

