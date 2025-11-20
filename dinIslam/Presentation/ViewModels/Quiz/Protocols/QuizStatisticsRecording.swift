//
//  QuizStatisticsRecording.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol QuizStatisticsRecording {
    var stats: UserStats { get }
    
    func recordQuizSession(_ summary: QuizSessionSummary)
    func getWrongQuestions(from allQuestions: [Question]) -> [Question]
    func removeWrongQuestion(_ questionId: String)
}

