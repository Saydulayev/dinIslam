//
//  FallbackQuestionSelectionStrategy.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class FallbackQuestionSelectionStrategy: QuestionSelectionStrategy {
    func selectQuestions(
        from allQuestions: [Question],
        progress: ProfileProgress,
        usedQuestionIds: Set<String>,
        sessionCount: Int
    ) -> [Question] {
        // Filter out already used questions
        let remainingNewQuestions = allQuestions.filter { question in
            !usedQuestionIds.contains(question.id)
        }
        
        // If not enough new questions, use all questions
        let availableQuestions = remainingNewQuestions.isEmpty ? allQuestions : remainingNewQuestions
        
        // Shuffle and take the needed amount
        let needed = min(sessionCount, availableQuestions.count)
        return Array(availableQuestions.shuffled().prefix(needed))
    }
}

