//
//  SyncedDataChange.swift
//  dinIslam
//
//  Хранилища данных (статистика, экзамены, достижения, пройденные вопросы) сообщают об изменениях
//  на устройстве; синхронизация отвечает на них отправкой снимка. Данные, пришедшие из iCloud,
//  хранилища записывают без уведомления, иначе синхронизация запускала бы сама себя.
//

import Foundation

extension Notification.Name {
    static let syncedDataDidChange = Notification.Name("SyncedDataDidChange")
}

enum SyncedDataChange {
    static let resetSectionsKey = "resetSections"

    /// - Parameter resetSections: группы, сброшенные на устройстве: для них начинается новое поколение
    static func post(resetSections: [SyncSection] = []) {
        NotificationCenter.default.post(
            name: .syncedDataDidChange,
            object: nil,
            userInfo: resetSections.isEmpty ? nil : [resetSectionsKey: resetSections]
        )
    }

    static func resetSections(from notification: Notification) -> [SyncSection] {
        notification.userInfo?[resetSectionsKey] as? [SyncSection] ?? []
    }
}
