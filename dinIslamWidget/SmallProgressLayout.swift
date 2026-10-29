//
//  SmallProgressLayout.swift
//  dinIslamWidget
//
//  Содержимое маленького виджета. Без статуса дня — компактный вариант для крупного шрифта,
//  когда ошибки к повторению и статус вместе не помещаются.
//

import SwiftUI

struct SmallProgressLayout: View {
    let entry: ProgressEntry
    let showsTodayStatus: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            StreakHeadline(entry: entry)

            Text(entry.streakLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            if entry.dueReviewCount > 0 {
                Label(entry.strings.dueReview(entry.dueReviewCount), systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption.bold())
                    .foregroundStyle(WidgetPalette.review)
                    .lineLimit(2)
            }

            if showsTodayStatus || entry.dueReviewCount == 0 {
                TodayStatusLabel(entry: entry)
            }
        }
    }
}
