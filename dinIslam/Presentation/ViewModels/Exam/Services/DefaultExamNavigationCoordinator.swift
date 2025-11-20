//
//  DefaultExamNavigationCoordinator.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

@MainActor
final class DefaultExamNavigationCoordinator: ExamNavigationCoordinating {
    var onShowResults: (() -> Void)?
    var onExitExam: (() -> Void)?
    var onRestartExam: (() -> Void)?
    
    func showResults() {
        onShowResults?()
    }
    
    func exitExam() {
        onExitExam?()
    }
    
    func restartExam() {
        onRestartExam?()
    }
}

