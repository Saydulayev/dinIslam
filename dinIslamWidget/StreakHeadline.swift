//
//  StreakHeadline.swift
//  dinIslamWidget
//
//  Огонь и число дней подряд — крупно, как на главном экране приложения.
//

import SwiftUI

struct StreakHeadline: View {
    let entry: ProgressEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(entry.streak > 0 ? WidgetPalette.flame : .secondary)
                .accessibilityHidden(true)
            Text(entry.streak, format: .number)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
        }
    }
}
