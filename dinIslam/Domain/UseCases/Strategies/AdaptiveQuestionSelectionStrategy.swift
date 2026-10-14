//
//  AdaptiveQuestionSelectionStrategy.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

final class AdaptiveQuestionSelectionStrategy: QuestionSelectionStrategy {
    private let adaptiveEngine: AdaptiveLearningEngine
    
    init(adaptiveEngine: AdaptiveLearningEngine) {
        self.adaptiveEngine = adaptiveEngine
    }
    
    func selectQuestions(
        from allQuestions: [Question],
        topicStats: [String: TopicStat],
        usedQuestionIds: Set<String>,
        sessionCount: Int
    ) -> [Question] {
        return adaptiveEngine.selectQuestions(
            from: allQuestions,
            topicStats: topicStats,
            usedQuestionIds: usedQuestionIds,
            sessionCount: sessionCount
        )
    }
}

