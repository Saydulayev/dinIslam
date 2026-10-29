//
//  ProgressWidget.swift
//  dinIslamWidget
//
//  Виджет «Серия и повторение»: дни подряд и ошибки, которые пора повторить.
//

import SwiftUI
import WidgetKit

@main
struct ProgressWidget: Widget {
    private let kind = "ProgressWidget"

    var body: some WidgetConfiguration {
        let strings = WidgetStrings(
            languageCode: WidgetSnapshotStore().load()?.languageCode ?? WidgetStrings.systemLanguageCode
        )
        return StaticConfiguration(kind: kind, provider: ProgressTimelineProvider()) { entry in
            ProgressWidgetView(entry: entry)
        }
        .configurationDisplayName(strings.text("widget.name"))
        .description(strings.text("widget.description"))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
