//
//  AdaptiveLearningEngine.swift
//  dinIslam
//
//  Created by Saydulayev on 12.01.26.
//

import Foundation

/// Подбор вопросов викторины: слабые темы в приоритете, остальное — поровну из разных тем
final class AdaptiveLearningEngine {
    func selectQuestions(
        from allQuestions: [Question],
        topicStats: [String: TopicStat],
        usedQuestionIds: Set<String>,
        sessionCount: Int
    ) -> [Question] {
        var selection: [Question] = []
        let weakTopics = Set(topicStats.filter { $0.value.isWeak }.keys)

        let newQuestions = allQuestions.filter { !usedQuestionIds.contains($0.id) }
        let reusedQuestions = allQuestions.filter { usedQuestionIds.contains($0.id) }

        // Приоритет - слабые темы, но не больше половины сессии
        let weakTopicQuestions = newQuestions.filter { weakTopics.contains($0.category) }
        selection.append(contentsOf: Self.balancedByTopic(weakTopicQuestions, count: sessionCount / 2))

        // Остальное — новые вопросы из разных тем поровну, чтобы сессия не сводилась к одной теме
        if selection.count < sessionCount {
            let selectedIds = Set(selection.map(\.id))
            let remainingNewQuestions = newQuestions.filter { !selectedIds.contains($0.id) }
            selection.append(contentsOf: Self.balancedByTopic(remainingNewQuestions, count: sessionCount - selection.count))
        }

        // Если все еще не хватает, добавляем повторные вопросы (для закрепления)
        if selection.count < sessionCount {
            let needed = sessionCount - selection.count
            selection.append(contentsOf: Array(reusedQuestions.shuffled().prefix(needed)))
        }

        if selection.count > sessionCount {
            selection = Array(selection.prefix(sessionCount))
        }

        return selection.shuffled()
    }

    // MARK: - Private Helpers
    /// Берёт вопросы по кругу из разных тем: сначала по одному из каждой, затем по второму и т. д.
    static func balancedByTopic(_ questions: [Question], count: Int) -> [Question] {
        guard count > 0 else { return [] }
        var queues = Dictionary(grouping: questions.shuffled(), by: \.category).values.shuffled().map { Array($0) }
        var result: [Question] = []
        while result.count < count, !queues.isEmpty {
            for index in queues.indices.reversed() where result.count < count {
                result.append(queues[index].removeFirst())
                if queues[index].isEmpty { queues.remove(at: index) }
            }
        }
        return result
    }
}
