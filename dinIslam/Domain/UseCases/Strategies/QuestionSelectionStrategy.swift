//
//  QuestionSelectionStrategy.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

protocol QuestionSelectionStrategy {
    func selectQuestions(
        from allQuestions: [Question],
        topicStats: [String: TopicStat],
        usedQuestionIds: Set<String>,
        sessionCount: Int
    ) -> [Question]
}

