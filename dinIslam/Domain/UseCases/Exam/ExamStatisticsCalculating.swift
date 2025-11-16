//
//  ExamStatisticsCalculating.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol ExamStatisticsCalculating {
    func calculateCorrectAnswers(
        answers: [String: ExamAnswer],
        questions: [Question]
    ) -> Int
    
    func calculateSkippedAnswers(answers: [String: ExamAnswer]) -> Int
    func calculateAnsweredCount(answers: [String: ExamAnswer]) -> Int
}

