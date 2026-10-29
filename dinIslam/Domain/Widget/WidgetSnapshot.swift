//
//  WidgetSnapshot.swift
//  dinIslam
//
//  Данные для виджета: серия дней и сроки повторения ошибок.
//  Файл входит и в виджет: значения на нужную дату виджет считает сам,
//  поэтому в полночь они меняются без запуска приложения.
//

import Foundation

nonisolated struct WidgetSnapshot: Codable, Equatable {
    /// Серия на день последнего занятия
    var currentStreak: Int
    var lastActiveDay: Date?
    /// Сроки повторения ошибок, по возрастанию
    var reviewDueDates: [Date]
    /// Язык приложения: тексты виджета — на нём, а не на языке системы
    var languageCode: String

    /// Приложение ещё не передало данные
    static func empty(languageCode: String) -> WidgetSnapshot {
        WidgetSnapshot(currentStreak: 0, lastActiveDay: nil, reviewDueDates: [], languageCode: languageCode)
    }

    func streak(at date: Date, calendar: Calendar = .current) -> Int {
        DayStreakRule.streak(currentStreak, lastActiveDay: lastActiveDay, at: date, calendar: calendar)
    }

    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        DayStreakRule.isActive(lastActiveDay: lastActiveDay, on: date, calendar: calendar)
    }

    func dueReviewCount(at date: Date) -> Int {
        reviewDueDates.filter { $0 <= date }.count
    }

    /// Когда меняется то, что показывает виджет: каждая полночь (серия, «сегодня») и сроки повторения
    func changeDates(after date: Date, days: Int, calendar: Calendar = .current) -> [Date] {
        let today = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: days, to: today) else { return [] }
        let midnights = (1...days).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        let dueDates = reviewDueDates.filter { $0 > date && $0 <= end }
        return Array(Set(midnights + dueDates)).sorted()
    }
}
