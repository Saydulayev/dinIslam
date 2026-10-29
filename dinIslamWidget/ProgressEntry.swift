//
//  ProgressEntry.swift
//  dinIslamWidget
//
//  Что показывает виджет в указанный момент.
//

import WidgetKit

struct ProgressEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let isActiveToday: Bool
    let dueReviewCount: Int
    let strings: WidgetStrings

    var streakLabel: String {
        strings.streakLabel(streak)
    }

    var todayStatus: String {
        strings.todayStatus(streak: streak, isActiveToday: isActiveToday)
    }
}

extension ProgressEntry {
    init(date: Date, snapshot: WidgetSnapshot) {
        self.init(
            date: date,
            streak: snapshot.streak(at: date),
            isActiveToday: snapshot.isActive(on: date),
            dueReviewCount: snapshot.dueReviewCount(at: date),
            strings: WidgetStrings(languageCode: snapshot.languageCode)
        )
    }

    /// Пример для галереи виджетов и заглушки при загрузке
    static func sample(date: Date, languageCode: String) -> ProgressEntry {
        ProgressEntry(
            date: date,
            streak: 7,
            isActiveToday: true,
            dueReviewCount: 3,
            strings: WidgetStrings(languageCode: languageCode)
        )
    }
}
