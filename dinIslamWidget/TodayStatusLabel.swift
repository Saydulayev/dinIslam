//
//  TodayStatusLabel.swift
//  dinIslamWidget
//
//  Занимались ли сегодня: если нет, серия прервётся в конце завтрашнего дня.
//

import SwiftUI

struct TodayStatusLabel: View {
    let entry: ProgressEntry

    var body: some View {
        Label(entry.todayStatus, systemImage: entry.isActiveToday ? "checkmark.circle.fill" : "circle.dashed")
            .font(.caption)
            .foregroundStyle(entry.isActiveToday ? WidgetPalette.success : .secondary)
            .lineLimit(2)
    }
}
