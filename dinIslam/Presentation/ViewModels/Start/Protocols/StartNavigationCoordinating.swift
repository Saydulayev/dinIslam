//
//  StartNavigationCoordinating.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import SwiftUI

protocol StartNavigationCoordinating: AnyObject {
    var navigationPath: NavigationPath { get set }
    
    func showQuiz()
    func showResult(_ snapshot: StartRoute.ResultSnapshot)
    func showAchievements()
    func showSettings()
    func showProfile()
    func showExam()
    func resetNavigation()
    func finishExamSession()
}

