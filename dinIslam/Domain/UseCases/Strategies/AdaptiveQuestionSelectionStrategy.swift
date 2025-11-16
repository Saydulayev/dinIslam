//
//  AdaptiveQuestionSelectionStrategy.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class AdaptiveQuestionSelectionStrategy: QuestionSelectionStrategy {
    private let adaptiveEngine: AdaptiveLearningEngine
    
    init(adaptiveEngine: AdaptiveLearningEngine) {
        self.adaptiveEngine = adaptiveEngine
    }
    
    func selectQuestions(
        from allQuestions: [Question],
        progress: ProfileProgress,
        usedQuestionIds: Set<String>,
        sessionCount: Int
    ) -> [Question] {
        return adaptiveEngine.selectQuestions(
            from: allQuestions,
            progress: progress,
            usedQuestionIds: usedQuestionIds,
            sessionCount: sessionCount
        )
    }
}

