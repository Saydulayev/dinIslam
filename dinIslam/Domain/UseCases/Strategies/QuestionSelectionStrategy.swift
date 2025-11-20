//
//  QuestionSelectionStrategy.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol QuestionSelectionStrategy {
    func selectQuestions(
        from allQuestions: [Question],
        progress: ProfileProgress,
        usedQuestionIds: Set<String>,
        sessionCount: Int
    ) -> [Question]
}

