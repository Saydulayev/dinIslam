//
//  QuizStatisticsRecording.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol QuizStatisticsRecording {
    var stats: UserStats { get }
    
    var dayStreak: Int { get }
    
    func recordQuizSession(_ summary: QuizSessionSummary)
    func registerDailyGoal()
    func getWrongQuestions(from allQuestions: [Question], scope: MistakesReviewScope) -> [Question]
    func recordReviewAnswers(_ answers: [String: Bool]) -> ReviewSessionSummary
}

