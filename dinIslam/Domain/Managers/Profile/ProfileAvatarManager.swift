//
//  ProfileAvatarManager.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class ProfileAvatarManager {
    private let localStore: ProfileLocalStore
    
    init(localStore: ProfileLocalStore) {
        self.localStore = localStore
    }
    
    func updateAvatar(
        profile: inout UserProfile,
        data: Data,
        fileExtension: String = "dat"
    ) -> Bool {
        guard let savedURL = localStore.saveAvatarData(data, for: profile.id, fileExtension: fileExtension) else {
            return false
        }
        profile.avatarURL = savedURL
        profile.metadata.updatedAt = Date()
        return true
    }
    
    func deleteAvatar(profile: inout UserProfile) {
        guard profile.avatarURL != nil else { return }
        localStore.deleteAvatar(for: profile.id)
        profile.avatarURL = nil
        profile.metadata.updatedAt = Date()
    }
    
    func validateAvatar(profile: inout UserProfile) {
        // Проверяем существование файла аватара
        if let avatarURL = profile.avatarURL {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: avatarURL.path) {
                // Файл не существует, пытаемся найти его в локальном хранилище
                if let existingAvatar = localStore.loadAvatar(for: profile.id) {
                    profile.avatarURL = existingAvatar
                } else {
                    // Файл не найден, очищаем avatarURL
                    profile.avatarURL = nil
                }
            }
        } else {
            // Если avatarURL отсутствует, но файл существует, восстанавливаем ссылку
            if let existingAvatar = localStore.loadAvatar(for: profile.id) {
                profile.avatarURL = existingAvatar
            }
        }
    }
}

