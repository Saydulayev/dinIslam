//
//  ProgressTimelineProvider.swift
//  dinIslamWidget
//
//  Лента виджета на неделю вперёд: значения меняются в полночь и в сроки повторения,
//  приложение обновляет ленту, когда меняются данные.
//

import WidgetKit

struct ProgressTimelineProvider: TimelineProvider {
    /// На сколько дней вперёд строится лента; дальше система запросит новую
    private static let timelineDays = 7
    private let store = WidgetSnapshotStore()

    func placeholder(in context: Context) -> ProgressEntry {
        .sample(date: Date(), languageCode: currentSnapshot().languageCode)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProgressEntry) -> Void) {
        let snapshot = currentSnapshot()
        let now = Date()
        completion(context.isPreview
            ? .sample(date: now, languageCode: snapshot.languageCode)
            : ProgressEntry(date: now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressEntry>) -> Void) {
        let snapshot = currentSnapshot()
        let now = Date()
        let dates = [now] + snapshot.changeDates(after: now, days: Self.timelineDays)
        let entries = dates.map { ProgressEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func currentSnapshot() -> WidgetSnapshot {
        store.load() ?? .empty(languageCode: WidgetStrings.systemLanguageCode)
    }
}
