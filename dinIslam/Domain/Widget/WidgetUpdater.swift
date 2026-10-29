//
//  WidgetUpdater.swift
//  dinIslam
//
//  Передаёт виджету серию дней и сроки повторения: при запуске, после изменения данных,
//  при уходе в фон (данные могли прийти из iCloud) и при смене языка.
//

import Foundation
import WidgetKit

final class WidgetUpdater {
    private let statsManager: StatsManager
    private let settingsManager: SettingsManager
    private let store: WidgetSnapshotStore
    private var dataChangeTask: Task<Void, Never>?

    init(
        statsManager: StatsManager,
        settingsManager: SettingsManager,
        store: WidgetSnapshotStore = WidgetSnapshotStore()
    ) {
        self.statsManager = statsManager
        self.settingsManager = settingsManager
        self.store = store

        dataChangeTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .syncedDataDidChange) {
                self?.update()
            }
        }
    }

    deinit {
        dataChangeTask?.cancel()
    }

    func update() {
        guard store.save(snapshot()) else { return }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func snapshot() -> WidgetSnapshot {
        let dailyProgress = statsManager.dailyProgress
        return WidgetSnapshot(
            currentStreak: dailyProgress.currentStreak,
            lastActiveDay: dailyProgress.lastActiveDay,
            reviewDueDates: statsManager.reviewSchedule.items.values.map(\.dueDate).sorted(),
            languageCode: settingsManager.settings.language.languageCode
        )
    }
}
