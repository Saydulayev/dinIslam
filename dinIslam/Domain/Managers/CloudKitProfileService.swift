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
    case newerFormat
    case iCloudUnavailable
    case unknown

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Не удалось закодировать данные для сохранения."
        case .decodingFailed:
            return "Не удалось прочитать данные из CloudKit."
        case .newerFormat:
            return "Данные в iCloud сохранены более новой версией приложения."
        case .iCloudUnavailable:
            return "iCloud временно недоступен."
        case .unknown:
            return "Неизвестная ошибка CloudKit."
        }
    }
}

/// Запись профиля в iCloud: снимок данных (SyncSnapshot) и фото
struct RemoteProfileRecord {
    let record: CKRecord
    /// `nil` — запись прежнего формата без снимка
    let snapshot: SyncSnapshot?
}

/// Что сделать с фото в записи при сохранении
enum AvatarUpload {
    case keep
    case upload(URL)
    case remove
}

/// Хранилище снимка в iCloud (в тестах — в памяти)
protocol ProfileCloudStoring: AnyObject {
    func accountId() async throws -> String
    func fetchProfileRecord() async throws -> RemoteProfileRecord?
    func fetchAvatarData() async throws -> Data?
    func save(_ snapshot: SyncSnapshot, to existingRecord: CKRecord?, avatar: AvatarUpload) async throws
}

final class CloudKitProfileService: ProfileCloudStoring {
    private let container: CKContainer
    private let database: CKDatabase
    private let recordType = "UserProfile"
    /// Личная база iCloud принадлежит одному аккаунту, поэтому профиль — одна запись с фиксированным именем
    private let profileRecordID = CKRecord.ID(recordName: "profile")
    private let snapshotKey = "snapshot"
    private let avatarKey = "avatar"

    init(containerIdentifier: String? = nil) {
        if let identifier = containerIdentifier {
            container = CKContainer(identifier: identifier)
        } else if let configuredIdentifier = Bundle.main.object(forInfoDictionaryKey: "CloudKitContainerIdentifier") as? String {
            container = CKContainer(identifier: configuredIdentifier)
        } else {
            container = CKContainer.default()
        }

        database = container.privateCloudDatabase
    }

    // MARK: - Account
    /// Синхронизация работает, только когда на устройстве выполнен вход в iCloud
    func accountStatus() async throws -> CKAccountStatus {
        try await container.accountStatus()
    }

    /// Идентификатор аккаунта iCloud: по нему видно, что на устройстве сменили Apple ID
    func accountId() async throws -> String {
        try await container.userRecordID().recordName
    }

    // MARK: - Record
    /// Запись без фото (фото скачивается отдельно и только когда изменилось); `nil` — записи ещё нет
    func fetchProfileRecord() async throws -> RemoteProfileRecord? {
        let record: CKRecord
        do {
            record = try await fetchRecord(desiredKeys: [snapshotKey])
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }

        guard let data = record[snapshotKey] as? Data else {
            return RemoteProfileRecord(record: record, snapshot: nil)
        }
        guard let snapshot = try? SyncSnapshot.decoded(from: data) else {
            throw CloudKitProfileError.decodingFailed
        }
        // Более новый формат может содержать данные, которые эта версия потеряла бы при перезаписи
        guard snapshot.format <= SyncSnapshot.currentFormat else {
            throw CloudKitProfileError.newerFormat
        }
        return RemoteProfileRecord(record: record, snapshot: snapshot)
    }

    func fetchAvatarData() async throws -> Data? {
        let record = try await fetchRecord(desiredKeys: [avatarKey])
        guard let assetURL = (record[avatarKey] as? CKAsset)?.fileURL else { return nil }
        return try Data(contentsOf: assetURL)
    }

    /// Сохраняет снимок в запись, прочитанную `fetchProfileRecord` (`nil` — создать запись).
    /// Если запись изменило другое устройство, бросает `CKError.serverRecordChanged`: снимок нужно слить заново.
    func save(_ snapshot: SyncSnapshot, to existingRecord: CKRecord?, avatar: AvatarUpload) async throws {
        let record = existingRecord ?? CKRecord(recordType: recordType, recordID: profileRecordID)
        guard let data = try? snapshot.encoded() else {
            throw CloudKitProfileError.encodingFailed
        }

        record[snapshotKey] = data as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        switch avatar {
        case .keep:
            break
        case .upload(let fileURL):
            record[avatarKey] = CKAsset(fileURL: fileURL)
        case .remove:
            record[avatarKey] = nil
        }

        _ = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: .ifServerRecordUnchanged)
            .saveResults[record.recordID]?.get()
    }

    // MARK: - Private Helpers
    private func fetchRecord(desiredKeys: [CKRecord.FieldKey]) async throws -> CKRecord {
        let results: [CKRecord.ID: Result<CKRecord, Error>]
        do {
            results = try await database.records(for: [profileRecordID], desiredKeys: desiredKeys)
        } catch let error as CKError where error.code == .partialFailure {
            throw error.partialErrorsByItemID?[profileRecordID] ?? error
        }
        guard let result = results[profileRecordID] else {
            throw CloudKitProfileError.unknown
        }
        return try result.get()
    }
}

extension Error {
    /// Запись изменило другое устройство между чтением и сохранением
    var isServerRecordChanged: Bool {
        guard let ckError = self as? CKError else { return false }
        if ckError.code == .serverRecordChanged { return true }
        if ckError.code == .partialFailure {
            return ckError.partialErrorsByItemID?.values.contains { ($0 as? CKError)?.code == .serverRecordChanged } ?? false
        }
        return false
    }
}
