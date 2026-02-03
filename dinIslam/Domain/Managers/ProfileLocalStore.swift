//
//  ProfileLocalStore.swift
//  dinIslam
//
//  Created by Saydulayev on 12.01.26.
//

import Foundation
import OSLog

final class ProfileLocalStore {
    private enum Constants {
        static let directoryName = "Profiles"
        static let currentProfileKey = "CurrentProfileID"
        static let anonymousProfileKey = "AnonymousProfileID"
    }

    private let fileManager: FileManager
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let directoryURL: URL
    private let avatarsDirectoryURL: URL

    init(
        fileManager: FileManager = .default,
        userDefaults: UserDefaults = .standard
    ) {
        self.fileManager = fileManager
        self.userDefaults = userDefaults

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directoryURL = baseDirectory.appendingPathComponent(Constants.directoryName, isDirectory: true)
        avatarsDirectoryURL = directoryURL.appendingPathComponent("Avatars", isDirectory: true)
        ensureDirectoryExists()
    }

    // MARK: - Public API
    func loadCurrentProfile() -> UserProfile? {
        guard let currentId = userDefaults.string(forKey: Constants.currentProfileKey) else {
            return nil
        }
        return loadProfile(withId: currentId)
    }

    func loadProfile(withId id: String) -> UserProfile? {
        let fileURL = profileURL(for: id)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(UserProfile.self, from: data)
        } catch {
            AppLogger.error("Failed to load profile \(id)", error: error, category: AppLogger.data)
            return nil
        }
    }

    func saveProfile(_ profile: UserProfile) {
        let fileURL = profileURL(for: profile.id)
        do {
            let data = try encoder.encode(profile)
            try data.write(to: fileURL, options: .atomic)
            userDefaults.set(profile.id, forKey: Constants.currentProfileKey)
            if profile.authMethod == .anonymous {
                userDefaults.set(profile.id, forKey: Constants.anonymousProfileKey)
            }
        } catch {
            AppLogger.error("Failed to save profile \(profile.id)", error: error, category: AppLogger.data)
        }
    }

    func deleteProfile(withId id: String) {
        let fileURL = profileURL(for: id)
        try? fileManager.removeItem(at: fileURL)
        if userDefaults.string(forKey: Constants.currentProfileKey) == id {
            userDefaults.removeObject(forKey: Constants.currentProfileKey)
        }
    }

    func loadOrCreateAnonymousProfile() -> UserProfile {
        if let anonymousId = userDefaults.string(forKey: Constants.anonymousProfileKey),
           let storedProfile = loadProfile(withId: anonymousId) {
            return storedProfile
        }

        let profile = UserProfile(
            id: UUID().uuidString,
            authMethod: .anonymous
        )
        saveProfile(profile)
        return profile
    }

    func setCurrentProfile(_ profile: UserProfile) {
        saveProfile(profile)
    }

    // MARK: - Helpers
    private func ensureDirectoryExists() {
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                AppLogger.error("Failed to create profiles directory", error: error, category: AppLogger.data)
            }
        }

        if !fileManager.fileExists(atPath: avatarsDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: avatarsDirectoryURL, withIntermediateDirectories: true)
            } catch {
                AppLogger.error("Failed to create avatars directory", error: error, category: AppLogger.data)
            }
        }
    }

    private func profileURL(for id: String) -> URL {
        directoryURL.appendingPathComponent("\(id).json")
    }

    private func avatarURL(for id: String, fileExtension: String = "dat") -> URL {
        avatarsDirectoryURL.appendingPathComponent("\(id).\(fileExtension)")
    }

    func saveAvatarData(_ data: Data, for profileId: String, fileExtension: String = "dat") -> URL? {
        deleteAvatar(for: profileId)
        let url = avatarURL(for: profileId, fileExtension: fileExtension)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            AppLogger.error("Failed to save avatar for \(profileId)", error: error, category: AppLogger.data)
            return nil
        }
    }

    func loadAvatar(for profileId: String) -> URL? {
        let directoryContents = (try? fileManager.contentsOfDirectory(at: avatarsDirectoryURL, includingPropertiesForKeys: nil)) ?? []
        return directoryContents.first { $0.lastPathComponent.hasPrefix(profileId) }
    }

    func deleteAvatar(for profileId: String) {
        guard let url = loadAvatar(for: profileId) else { return }
        try? fileManager.removeItem(at: url)
    }
}

