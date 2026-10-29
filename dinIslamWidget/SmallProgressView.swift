//
//  SmallProgressView.swift
//  dinIslamWidget
//
//  Маленький виджет: серия, ошибки к повторению, занимались ли сегодня.
//

import SwiftUI
import WidgetKit

struct SmallProgressView: View {
    let entry: ProgressEntry

    var body: some View {
        // При крупном шрифте строка повторения и статус дня вместе не помещаются:
        // тогда остаётся только повторение — по нему виджет и открывает приложение
        ViewThatFits(in: .vertical) {
            SmallProgressLayout(entry: entry, showsTodayStatus: true)
            SmallProgressLayout(entry: entry, showsTodayStatus: false)
        }
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .environment(\.colorScheme, .dark)
    }
}

#Preview(as: .systemSmall) {
    ProgressWidget()
} timeline: {
    ProgressEntry.sample(date: .now, languageCode: "ru")
    ProgressEntry(date: .now, streak: 0, isActiveToday: false, dueReviewCount: 0, strings: WidgetStrings(languageCode: "ru"))
    ProgressEntry(date: .now, streak: 12, isActiveToday: false, dueReviewCount: 26, strings: WidgetStrings(languageCode: "ru"))
}
