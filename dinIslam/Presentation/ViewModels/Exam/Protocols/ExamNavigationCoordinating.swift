//
//  ExamNavigationCoordinating.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

@MainActor
protocol ExamNavigationCoordinating {
    func showResults()
    func exitExam()
    func restartExam()
}

