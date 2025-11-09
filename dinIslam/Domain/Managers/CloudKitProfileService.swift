//
//  CloudKitProfileService.swift
//  dinIslam
//
//  Created by GPT-5 Codex on 09.11.25.
//

import CloudKit
import Foundation

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
    private let localStore: ProfileLocalStore
    private let fileManager = FileManager.default

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
            let record = try await fetchRecord(with: recordID)
            return try decodeProfile(from: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func saveProfile(_ profile: UserProfile) async throws -> UserProfile {
        let recordID = CKRecord.ID(recordName: profile.id)
        let record: CKRecord

        if let existingRecord = try? await fetchRecord(with: recordID) {
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
            print("⚠️ Profile \(userId) already deleted: \(error)")
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

        if let avatarURL = profile.avatarURL, fileManager.fileExists(atPath: avatarURL.path) {
            record["avatar"] = CKAsset(fileURL: avatarURL)
        } else {
            record["avatar"] = nil
        }
    }

    private func decodeProfile(from record: CKRecord) throws -> UserProfile {
        guard let data = record["payload"] as? Data else {
            throw CloudKitProfileError.decodingFailed
        }

        guard var profile = try? decoder.decode(UserProfile.self, from: data) else {
            throw CloudKitProfileError.decodingFailed
        }

        if let asset = record["avatar"] as? CKAsset,
           let assetURL = asset.fileURL,
           let avatarData = try? Data(contentsOf: assetURL) {
            let fileExtension = assetURL.pathExtension.isEmpty ? "dat" : assetURL.pathExtension
            profile.avatarURL = localStore.saveAvatarData(avatarData, for: profile.id, fileExtension: fileExtension)
        } else if let existingAvatar = localStore.loadAvatar(for: profile.id) {
            profile.avatarURL = existingAvatar
        } else {
            profile.avatarURL = nil
        }

        profile.metadata.lastSyncedAt = record.modificationDate
        return profile
    }

    private func fetchRecord(with id: CKRecord.ID) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            database.fetch(withRecordID: id) { record, error in
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

