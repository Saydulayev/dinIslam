//
//  WidgetSnapshotStore.swift
//  dinIslam
//
//  Снимок для виджета в общей группе приложений (App Group). Файл входит и в виджет.
//

import Foundation

nonisolated struct WidgetSnapshotStore {
    static let appGroupId = "group.com.saydulayev.dinIslam"
    private static let key = "WidgetSnapshot"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: WidgetSnapshotStore.appGroupId)) {
        self.defaults = defaults
    }

    func load() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// - Returns: изменился ли снимок. Виджет обновляется только при изменении:
    ///   число обновлений у системы ограничено
    @discardableResult
    func save(_ snapshot: WidgetSnapshot) -> Bool {
        guard let defaults, snapshot != load(),
              let data = try? JSONEncoder().encode(snapshot) else { return false }
        defaults.set(data, forKey: Self.key)
        return true
    }
}
