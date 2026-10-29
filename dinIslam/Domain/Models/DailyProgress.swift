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
        DayStreakRule.streak(currentStreak, lastActiveDay: lastActiveDay, at: date, calendar: calendar)
    }

    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        DayStreakRule.isActive(lastActiveDay: lastActiveDay, on: date, calendar: calendar)
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

// MARK: - Decoding
// Отсутствующее поле получает значение по умолчанию, а не обнуляет серию (см. StoredDataDecoding.swift)
// MARK: - Sync
extension DailyProgress {
    /// Слияние с другим устройством: серия — с устройства, где занимались позже
    /// (в тот же день — бо́льшая), рекорд и день выполнения цели — наибольшие
    static func merged(_ lhs: DailyProgress, _ rhs: DailyProgress) -> DailyProgress {
        let lhsDay = lhs.lastActiveDay ?? .distantPast
        let rhsDay = rhs.lastActiveDay ?? .distantPast
        var result: DailyProgress
        if lhsDay != rhsDay {
            result = lhsDay > rhsDay ? lhs : rhs
        } else {
            result = lhs.currentStreak >= rhs.currentStreak ? lhs : rhs
        }
        result.longestStreak = max(lhs.longestStreak, rhs.longestStreak, result.currentStreak)
        result.lastDailyGoalDay = [lhs.lastDailyGoalDay, rhs.lastDailyGoalDay].compactMap { $0 }.max()
        return result
    }
}

extension DailyProgress {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentStreak = container.decode(.currentStreak, default: 0)
        longestStreak = container.decode(.longestStreak, default: 0)
        lastActiveDay = container.decodeOptional(.lastActiveDay)
        lastDailyGoalDay = container.decodeOptional(.lastDailyGoalDay)
    }
}
