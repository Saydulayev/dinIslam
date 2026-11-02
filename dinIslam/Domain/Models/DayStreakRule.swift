//
//  DayStreakRule.swift
//  dinIslam
//
//  Правило серии дней. Файл входит и в виджет: приложение и виджет считают серию одинаково.
//  Заморозка сохраняет серию за один пропущенный день; тратится, только когда серию спасает.
//

import Foundation

nonisolated enum DayStreakRule {
    /// Одна заморозка за каждые столько дней подряд
    static let freezeEarnInterval = 7
    static let maxStreakFreezes = 2

    /// Серия на указанный момент: если пропущенных дней больше, чем заморозок, серия прервана
    static func streak(_ currentStreak: Int, lastActiveDay: Date?, freezes: Int, at date: Date, calendar: Calendar) -> Int {
        guard let missed = missedDays(lastActiveDay: lastActiveDay, at: date, calendar: calendar) else { return 0 }
        return missed <= freezes ? currentStreak : 0
    }

    /// Сколько пропущенных дней серии закрывают заморозки (0 — пропусков нет или серия прервана)
    static func frozenDays(lastActiveDay: Date?, freezes: Int, at date: Date, calendar: Calendar) -> Int {
        guard let missed = missedDays(lastActiveDay: lastActiveDay, at: date, calendar: calendar) else { return 0 }
        return missed <= freezes ? missed : 0
    }

    static func isActive(lastActiveDay: Date?, on date: Date, calendar: Calendar) -> Bool {
        guard let lastActiveDay else { return false }
        return calendar.isDate(lastActiveDay, inSameDayAs: date)
    }

    /// Полные дни без занятий между последним занятием и сегодняшним днём
    private static func missedDays(lastActiveDay: Date?, at date: Date, calendar: Calendar) -> Int? {
        guard let lastActiveDay else { return nil }
        let today = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
        return max(days - 1, 0)
    }
}
