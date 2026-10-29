//
//  MediumProgressView.swift
//  dinIslamWidget
//
//  Средний виджет: слева серия и статус дня, справа ошибки к повторению.
//

import SwiftUI
import WidgetKit

struct MediumProgressView: View {
    let entry: ProgressEntry

    private var hasDueReview: Bool {
        entry.dueReviewCount > 0
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                StreakHeadline(entry: entry)

                Text(entry.streakLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                TodayStatusLabel(entry: entry)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Divider()

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title2)
                        .foregroundStyle(hasDueReview ? WidgetPalette.review : .secondary)
                        .accessibilityHidden(true)
                    Text(entry.dueReviewCount, format: .number)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                }

                Text(entry.strings.text(hasDueReview ? "widget.review.dueLabel" : "widget.review.none"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
        .minimumScaleFactor(0.8)
        .environment(\.colorScheme, .dark)
    }
}

#Preview(as: .systemMedium) {
    ProgressWidget()
} timeline: {
    ProgressEntry.sample(date: .now, languageCode: "ru")
    ProgressEntry(date: .now, streak: 12, isActiveToday: false, dueReviewCount: 0, strings: WidgetStrings(languageCode: "en"))
}
