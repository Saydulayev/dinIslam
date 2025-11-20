//
//  QuizFeedbackProviding.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol QuizFeedbackProviding {
    func answerSelected(isCorrect: Bool)
    func quizCompleted(success: Bool)
    func selectionChanged()
    func questionSkipped()
    func questionPaused()
    func questionResumed()
}

