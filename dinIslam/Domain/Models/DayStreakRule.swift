//
//  DayStreakRule.swift
//  dinIslam
//
//  Правило серии дней. Файл входит и в виджет: приложение и виджет считают серию одинаково.
//

import Foundation

nonisolated enum DayStreakRule {
    /// Серия на указанный момент: если вчера и сегодня занятий не было, серия прервана
    static func streak(_ currentStreak: Int, lastActiveDay: Date?, at date: Date, calendar: Calendar) -> Int {
        guard let lastActiveDay else { return 0 }
        let today = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
        return days <= 1 ? currentStreak : 0
    }

    static func isActive(lastActiveDay: Date?, on date: Date, calendar: Calendar) -> Bool {
        guard let lastActiveDay else { return false }
        return calendar.isDate(lastActiveDay, inSameDayAs: date)
    }
}
