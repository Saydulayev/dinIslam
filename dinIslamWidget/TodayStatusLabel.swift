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
        Label(entry.todayStatus, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(entry.isActiveToday ? WidgetPalette.success : .secondary)
            .lineLimit(2)
    }

    private var systemImage: String {
        if entry.isActiveToday {
            return "checkmark.circle.fill"
        }
        return entry.isHeldByFreeze ? "snowflake" : "circle.dashed"
    }
}
