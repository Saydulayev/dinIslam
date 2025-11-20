//
//  DefaultExamStatisticsCalculator.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

struct DefaultExamStatisticsCalculator: ExamStatisticsCalculating {
    func calculateCorrectAnswers(
        answers: [String: ExamAnswer],
        questions: [Question]
    ) -> Int {
        answers.values.filter { answer in
            guard let question = questions.first(where: { $0.id == answer.questionId }),
                  let selectedIndex = answer.selectedAnswerIndex,
                  !answer.isSkipped && !answer.isTimeExpired else {
                return false
            }
            return selectedIndex == question.correctIndex
        }.count
    }
    
    func calculateSkippedAnswers(answers: [String: ExamAnswer]) -> Int {
        answers.values.filter { $0.isSkipped || $0.isTimeExpired }.count
    }
    
    func calculateAnsweredCount(answers: [String: ExamAnswer]) -> Int {
        answers.values.filter { !$0.isSkipped && !$0.isTimeExpired }.count
    }
}

