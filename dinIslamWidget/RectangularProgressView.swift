//
//  RectangularProgressView.swift
//  dinIslamWidget
//
//  Прямоугольный виджет на экране блокировки: серия и ошибки к повторению (или статус дня).
//

import SwiftUI
import WidgetKit

struct RectangularProgressView: View {
    let entry: ProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("\(entry.streak) \(entry.streakLabel)", systemImage: "flame.fill")
                .font(.headline)
                .widgetAccentable()

            Text(entry.dueReviewCount > 0 ? entry.strings.dueReview(entry.dueReviewCount) : entry.todayStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
