//
//  ReviewSchedule.swift
//  dinIslam
//
//  Интервальное повторение ошибок: вопрос возвращается через 1, 3, 7 и 14 дней.
//  После правильного ответа на каждом этапе вопрос считается выученным.
//  Ошибка возвращает вопрос к началу (повтор завтра).
//

import Foundation

struct ReviewItem: Codable, Equatable {
    /// Сколько интервальных повторений уже пройдено
    var stage: Int
    var dueDate: Date
}

enum ReviewOutcome: Equatable {
    /// Вопрос не отслеживается
    case notTracked
    /// Правильный ответ раньше срока — расписание не меняется
    case notDue
    /// Правильный ответ в срок — следующий повтор позже
    case advanced(nextDue: Date)
    /// Все этапы пройдены — вопрос выучен
    case graduated
    /// Ошибка — повтор завтра
    case reset(nextDue: Date)
}

struct ReviewSchedule: Codable, Equatable {
    static let intervalsInDays = [1, 3, 7, 14]

    private(set) var items: [String: ReviewItem] = [:]

    var count: Int { items.count }

    func isTracked(_ questionId: String) -> Bool {
        items[questionId] != nil
    }

    func dueIds(at date: Date) -> Set<String> {
        Set(items.filter { $0.value.dueDate <= date }.map(\.key))
    }

    func dueCount(at date: Date) -> Int {
        items.values.filter { $0.dueDate <= date }.count
    }

    /// Ближайшая дата повторения среди ещё не наступивших
    func nextDueDate(after date: Date) -> Date? {
        items.values.map(\.dueDate).filter { $0 > date }.min()
    }

    /// Новая ошибка (или повторная) — вопрос вернётся завтра
    mutating func registerMistake(_ questionId: String, at date: Date, calendar: Calendar = .current) {
        items[questionId] = ReviewItem(stage: 0, dueDate: Self.dueDate(afterDays: Self.intervalsInDays[0], from: date, calendar: calendar))
    }

    @discardableResult
    mutating func recordAnswer(
        _ questionId: String,
        isCorrect: Bool,
        at date: Date,
        calendar: Calendar = .current
    ) -> ReviewOutcome {
        guard var item = items[questionId] else { return .notTracked }

        guard isCorrect else {
            registerMistake(questionId, at: date, calendar: calendar)
            return .reset(nextDue: items[questionId]?.dueDate ?? date)
        }

        guard item.dueDate <= date else { return .notDue }

        item.stage += 1
        guard item.stage < Self.intervalsInDays.count else {
            items[questionId] = nil
            return .graduated
        }

        item.dueDate = Self.dueDate(afterDays: Self.intervalsInDays[item.stage], from: date, calendar: calendar)
        items[questionId] = item
        return .advanced(nextDue: item.dueDate)
    }

    mutating func remove(_ questionId: String) {
        items[questionId] = nil
    }

    mutating func removeAll() {
        items.removeAll()
    }

    /// Приводит расписание к списку ошибок: ошибки без расписания (появились до этой функции)
    /// становятся доступны для повторения сразу, лишние записи удаляются.
    mutating func sync(with wrongQuestionIds: Set<String>, now: Date) {
        for id in items.keys where !wrongQuestionIds.contains(id) {
            items[id] = nil
        }
        for id in wrongQuestionIds where items[id] == nil {
            items[id] = ReviewItem(stage: 0, dueDate: now)
        }
    }

    /// Срок — начало дня, чтобы вопрос был доступен с утра, а не в то же время суток
    private static func dueDate(afterDays days: Int, from date: Date, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: days, to: startOfDay) ?? date.addingTimeInterval(TimeInterval(days) * 86_400)
    }
}
