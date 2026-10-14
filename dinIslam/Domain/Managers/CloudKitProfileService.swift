//
//  CloudKitProfileService.swift
//  dinIslam
//
//  Created by Saydulayev on 12.01.26.
//

import CloudKit
import Foundation
import OSLog

enum CloudKitProfileError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Не удалось закодировать профиль для сохранения."
        case .decodingFailed:
            return "Не удалось декодировать профиль из CloudKit."
        case .unknown:
            return "Неизвестная ошибка CloudKit."
        }
    }
}

final class CloudKitProfileService {
    private let container: CKContainer
    private let database: CKDatabase
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let recordType = "UserProfile"
    private let avatarKey = "avatar"
    /// Отпечаток фото в записи: `""` — фото нет, `nil` — запись старого формата
    private let avatarHashKey = "avatarHash"
    /// Поля записи без фото: фото скачивается отдельно и только если изменилось
    private var profileKeys: [CKRecord.FieldKey] {
        ["payload", "updatedAt", "createdAt", "authMethod", "locale", avatarHashKey]
    }
    private let localStore: ProfileLocalStore

    init(containerIdentifier: String? = nil, localStore: ProfileLocalStore = ProfileLocalStore()) {
        if let identifier = containerIdentifier {
            container = CKContainer(identifier: identifier)
        } else if let configuredIdentifier = Bundle.main.object(forInfoDictionaryKey: "CloudKitContainerIdentifier") as? String {
            container = CKContainer(identifier: configuredIdentifier)
        } else {
            container = CKContainer.default()
        }

        database = container.privateCloudDatabase
        self.localStore = localStore

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - CRUD
    func fetchProfile(for userId: String) async throws -> UserProfile? {
        let recordID = CKRecord.ID(recordName: userId)
        do {
            let record = try await fetchRecord(with: recordID, desiredKeys: profileKeys)
            var profile = try decodeProfile(from: record)
            await downloadAvatarIfChanged(for: &profile, record: record)
            return profile
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func saveProfile(_ profile: UserProfile) async throws -> UserProfile {
        let recordID = CKRecord.ID(recordName: profile.id)
        let record: CKRecord

        if let existingRecord = try? await fetchRecord(with: recordID, desiredKeys: profileKeys) {
            record = existingRecord
        } else {
            record = CKRecord(recordType: recordType, recordID: recordID)
        }

        try encode(profile, into: record)
        let savedRecord = try await save(record: record)
        return try decodeProfile(from: savedRecord)
    }

    func deleteProfile(with userId: String) async throws {
        let recordID = CKRecord.ID(recordName: userId)
        do {
            try await delete(recordID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            AppLogger.warning("Profile \(userId) already deleted: \(error.localizedDescription)", category: AppLogger.data)
        }
    }

    // MARK: - Private Helpers
    private func encode(_ profile: UserProfile, into record: CKRecord) throws {
        guard let data = try? encoder.encode(profile) else {
            throw CloudKitProfileError.encodingFailed
        }

        record["payload"] = data as CKRecordValue
        record["updatedAt"] = profile.metadata.updatedAt as CKRecordValue
        record["createdAt"] = profile.metadata.createdAt as CKRecordValue
        record["authMethod"] = profile.authMethod.rawValue as CKRecordValue
        record["locale"] = profile.localeIdentifier as CKRecordValue

        // Фото передаётся только при изменении: иначе поле не трогаем, и CloudKit его не загружает
        let remoteHash = record[avatarHashKey] as? String
        if let avatarURL = profile.avatarURL,
           let localHash = AvatarImageProcessor.fingerprint(ofFileAt: avatarURL) {
            if localHash != remoteHash {
                record[avatarKey] = CKAsset(fileURL: avatarURL)
                record[avatarHashKey] = localHash as CKRecordValue
            }
        } else if remoteHash != "" {
            record[avatarKey] = nil
            record[avatarHashKey] = "" as CKRecordValue
        }
    }

    private func decodeProfile(from record: CKRecord) throws -> UserProfile {
        guard let data = record["payload"] as? Data else {
            throw CloudKitProfileError.decodingFailed
        }

        guard var profile = try? decoder.decode(UserProfile.self, from: data) else {
            throw CloudKitProfileError.decodingFailed
        }

        // Фото берётся из локального файла; новое фото из CloudKit скачивает downloadAvatarIfChanged.
        // Отсутствие фото в записи локальный файл не удаляет — иначе refreshFromCloud
        // мог бы подтянуть старую запись и стереть только что выбранное фото.
        profile.avatarURL = localStore.loadAvatar(for: profile.id)

        profile.metadata.lastSyncedAt = record.modificationDate
        return profile
    }

    /// Скачивает фото, если его отпечаток в записи отличается от локального файла.
    /// Ошибка скачивания не мешает загрузке профиля: остаётся локальное фото.
    private func downloadAvatarIfChanged(for profile: inout UserProfile, record: CKRecord) async {
        let remoteHash = record[avatarHashKey] as? String
        guard remoteHash != "" else { return }
        let localHash = profile.avatarURL.flatMap { AvatarImageProcessor.fingerprint(ofFileAt: $0) }
        if let remoteHash, remoteHash == localHash { return }

        guard let avatarRecord = try? await fetchRecord(with: record.recordID, desiredKeys: [avatarKey]),
              let assetURL = (avatarRecord[avatarKey] as? CKAsset)?.fileURL,
              let remoteData = try? Data(contentsOf: assetURL) else {
            return
        }
        // В записях старого формата (без отпечатка) фото исходного размера — уменьшаем при сохранении
        let avatarData = remoteHash == nil ? AvatarImageProcessor.prepare(remoteData) : remoteData
        guard let avatarData,
              let savedURL = localStore.saveAvatarData(avatarData, for: profile.id, fileExtension: AvatarImageProcessor.fileExtension) else {
            return
        }
        profile.avatarURL = savedURL
    }

    private func fetchRecord(with id: CKRecord.ID, desiredKeys: [CKRecord.FieldKey]) async throws -> CKRecord {
        let results: [CKRecord.ID: Result<CKRecord, Error>]
        do {
            results = try await database.records(for: [id], desiredKeys: desiredKeys)
        } catch let error as CKError where error.code == .partialFailure {
            throw error.partialErrorsByItemID?[id] ?? error
        }
        guard let result = results[id] else {
            throw CloudKitProfileError.unknown
        }
        return try result.get()
    }

    private func save(record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            database.save(record) { record, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let record = record {
                    continuation.resume(returning: record)
                } else {
                    continuation.resume(throwing: CloudKitProfileError.unknown)
                }
            }
        }
    }

    private func delete(recordID: CKRecord.ID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            database.delete(withRecordID: recordID) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

