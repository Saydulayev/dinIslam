//
//  DefaultQuizFeedbackProvider.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class DefaultQuizFeedbackProvider: QuizFeedbackProviding {
    private let hapticManager: HapticManager
    private let soundManager: SoundManager
    
    init(hapticManager: HapticManager, soundManager: SoundManager) {
        self.hapticManager = hapticManager
        self.soundManager = soundManager
    }
    
    func answerSelected(isCorrect: Bool) {
        if isCorrect {
            hapticManager.success()
            soundManager.playSuccessSound()
        } else {
            hapticManager.error()
            soundManager.playErrorSound()
        }
    }
    
    func quizCompleted(success: Bool) {
        hapticManager.success()
        soundManager.playSuccessSound()
    }
    
    func selectionChanged() {
        hapticManager.selectionChanged()
        soundManager.playSelectionSound()
    }
    
    func questionSkipped() {
        hapticManager.selectionChanged()
        soundManager.playSelectionSound()
    }
    
    func questionPaused() {
        hapticManager.selectionChanged()
    }
    
    func questionResumed() {
        hapticManager.selectionChanged()
    }
}

