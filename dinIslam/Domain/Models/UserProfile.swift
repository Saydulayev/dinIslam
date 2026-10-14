//
//  UserProfile.swift
//  dinIslam
//
//  Created by Saydulayev on 12.01.26.
//

import Foundation

// MARK: - User Profile
/// Имя и фото на устройстве. Прогресс хранят StatsManager, ExamStatisticsManager, AchievementManager
/// и QuestionPoolProgressManager; в iCloud всё уходит одним снимком (SyncSnapshot).
struct UserProfile: Codable, Identifiable, Equatable {
    struct Metadata: Codable, Equatable {
        var createdAt: Date
        var updatedAt: Date
        var lastSyncedAt: Date?
    }

    /// Локальный идентификатор профиля на устройстве (имена файлов профиля и фото)
    var id: String
    var customDisplayName: String?
    /// Когда изменили имя: при синхронизации побеждает более позднее изменение
    var displayNameUpdatedAt: Date
    var avatarURL: URL?
    /// Когда выбрали или удалили фото
    var avatarUpdatedAt: Date
    var metadata: Metadata

    init(
        id: String,
        customDisplayName: String? = nil,
        displayNameUpdatedAt: Date = .distantPast,
        avatarURL: URL? = nil,
        avatarUpdatedAt: Date = .distantPast,
        metadata: Metadata = Metadata(createdAt: Date(), updatedAt: Date(), lastSyncedAt: nil)
    ) {
        self.id = id
        self.customDisplayName = customDisplayName
        self.displayNameUpdatedAt = displayNameUpdatedAt
        self.avatarURL = avatarURL
        self.avatarUpdatedAt = avatarUpdatedAt
        self.metadata = metadata
    }
}

// MARK: - Decoding
// Каждое поле читается отдельно: новое поле не делает нечитаемым весь профиль (см. StoredDataDecoding.swift).
// Поля прежних версий (сводка прогресса, настройки, способ входа) игнорируются.

extension UserProfile {
    private enum LegacyCodingKeys: String, CodingKey {
        case fullName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        // Имя из прежнего входа через Apple становится обычным отображаемым именем
        let legacyFullName: String? = (try? decoder.container(keyedBy: LegacyCodingKeys.self))?.decodeOptional(.fullName)
        customDisplayName = container.decodeOptional(.customDisplayName) ?? legacyFullName
        displayNameUpdatedAt = container.decode(.displayNameUpdatedAt, default: .distantPast)
        avatarURL = container.decodeOptional(.avatarURL)
        avatarUpdatedAt = container.decode(.avatarUpdatedAt, default: .distantPast)
        metadata = container.decode(.metadata, default: Metadata(createdAt: .distantPast, updatedAt: .distantPast))
    }
}

extension UserProfile.Metadata {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        createdAt = container.decode(.createdAt, default: .distantPast)
        updatedAt = container.decode(.updatedAt, default: .distantPast)
        lastSyncedAt = container.decodeOptional(.lastSyncedAt)
    }
}
