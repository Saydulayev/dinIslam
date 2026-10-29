//
//  CircularProgressView.swift
//  dinIslamWidget
//
//  Круглый виджет на экране блокировки: дни подряд.
//

import SwiftUI
import WidgetKit

struct CircularProgressView: View {
    let entry: ProgressEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .widgetAccentable()
                Text(entry.streak, format: .number)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.streak) \(entry.streakLabel)")
    }
}
