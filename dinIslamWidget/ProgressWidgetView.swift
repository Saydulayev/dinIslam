//
//  ProgressWidgetView.swift
//  dinIslamWidget
//
//  Вид виджета для каждого размера. Нажатие при ошибках к повторению открывает повторение.
//

import SwiftUI
import WidgetKit

struct ProgressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ProgressEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MediumProgressView(entry: entry)
            case .accessoryCircular:
                CircularProgressView(entry: entry)
            case .accessoryRectangular:
                RectangularProgressView(entry: entry)
            case .accessoryInline:
                InlineProgressView(entry: entry)
            default:
                SmallProgressView(entry: entry)
            }
        }
        .widgetURL(entry.dueReviewCount > 0 ? WidgetLink.review : nil)
        .containerBackground(for: .widget) {
            WidgetPalette.background
        }
    }
}
