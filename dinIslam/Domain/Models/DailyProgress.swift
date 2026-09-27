//
//  DailyProgress.swift
//  dinIslam
//
//  Серия дней с занятиями и ежедневная цель («5 вопросов в день»).
//  День засчитывается за любую завершённую сессию: викторину, ежедневную практику или повторение.
//

import Foundation

struct DailyProgress: Codable, Equatable {
    static let dailyGoalQuestions = 5

    private(set) var currentStreak: Int = 0
    private(set) var longestStreak: Int = 0
    private(set) var lastActiveDay: Date?
    private(set) var lastDailyGoalDay: Date?

    /// Серия на указанный момент: если вчера и сегодня занятий не было, серия прервана
    func streak(at date: Date, calendar: Calendar = .current) -> Int {
        guard let lastActiveDay else { return 0 }
        let today = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
        return days <= 1 ? currentStreak : 0
    }

    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let lastActiveDay else { return false }
        return calendar.isDate(lastActiveDay, inSameDayAs: date)
    }

    func isDailyGoalCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let lastDailyGoalDay else { return false }
        return calendar.isDate(lastDailyGoalDay, inSameDayAs: date)
    }

    mutating func registerActivity(at date: Date, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: date)

        if let lastActiveDay {
            let days = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
            switch days {
            case ..<1:
                return // уже засчитано сегодня (или часы переведены назад)
            case 1:
                currentStreak += 1
            default:
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        lastActiveDay = today
        longestStreak = max(longestStreak, currentStreak)
    }

    mutating func registerDailyGoal(at date: Date, calendar: Calendar = .current) {
        registerActivity(at: date, calendar: calendar)
        lastDailyGoalDay = calendar.startOfDay(for: date)
    }
}
