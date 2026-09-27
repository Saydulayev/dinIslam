//
//  SessionReport.swift
//  dinIslam
//
//  Итог сессии для экрана результата: темы, ошибки, серия, повторение.
//

import Foundation

enum QuizSessionKind: Hashable {
    /// Обычная викторина (20 вопросов)
    case standard
    /// Ежедневная практика (5 вопросов)
    case daily
    /// Повторение ошибок
    case review
}

/// Какие ошибки повторять
enum MistakesReviewScope: Hashable {
    /// Только те, у которых наступил срок
    case due
    /// Все ошибки
    case all
    /// Конкретные вопросы (например, ошибки только что завершённой сессии)
    case questions(Set<String>)
}

struct ReviewSessionSummary: Hashable {
    /// Вопросы, прошедшие все этапы повторения
    var graduated = 0
    /// Правильные ответы в срок: вопрос вернётся позже
    var advanced = 0
    /// Ошибки: вопрос вернётся завтра
    var reset = 0
    /// Правильные ответы раньше срока: расписание не изменилось
    var notDue = 0
    /// Сколько вопросов осталось в повторении
    var remaining = 0
    var nextDueDate: Date?
}

struct SessionReport: Hashable {
    struct TopicResult: Hashable, Identifiable {
        let categoryId: String
        let correct: Int
        let total: Int

        var id: String { categoryId }

        var accuracy: Double {
            total > 0 ? Double(correct) / Double(total) : 0
        }
    }

    let kind: QuizSessionKind
    let topicResults: [TopicResult]
    let mistakeIds: [String]
    let dayStreak: Int
    let review: ReviewSessionSummary?

    /// Разбивка по темам имеет смысл, только если у вопросов указаны темы
    var hasTopicBreakdown: Bool {
        topicResults.contains { $0.categoryId != QuestionCategory.generalId }
    }

    static func topicResults(for outcomes: [QuizQuestionOutcome]) -> [TopicResult] {
        let grouped = Dictionary(grouping: outcomes) { (outcome: QuizQuestionOutcome) in outcome.category }
        let results: [TopicResult] = grouped.map { categoryId, items in
            TopicResult(
                categoryId: categoryId,
                correct: items.filter { $0.isCorrect }.count,
                total: items.count
            )
        }
        return results.sorted { lhs, rhs in
            if lhs.total != rhs.total { return lhs.total > rhs.total }
            return lhs.categoryId < rhs.categoryId
        }
    }
}
