//
//  ProfileAvatarManager.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

final class ProfileAvatarManager {
    private let localStore: ProfileLocalStore
    
    init(localStore: ProfileLocalStore) {
        self.localStore = localStore
    }
    
    /// Сохраняет фото уменьшенным до 512 px, в JPEG без метаданных.
    func updateAvatar(profile: inout UserProfile, data: Data) -> Bool {
        guard let preparedData = AvatarImageProcessor.prepare(data),
              let savedURL = localStore.saveAvatarData(preparedData, for: profile.id, fileExtension: AvatarImageProcessor.fileExtension) else {
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
        migrateLegacyAvatar(profile: &profile)
    }

    /// Фото, сохранённые до уменьшения (исходный размер, с метаданными), пересохраняются один раз.
    /// Обработанное фото хранится с расширением `jpg`; при следующей синхронизации оно уйдёт в iCloud.
    private func migrateLegacyAvatar(profile: inout UserProfile) {
        guard let avatarURL = profile.avatarURL,
              avatarURL.pathExtension != AvatarImageProcessor.fileExtension,
              let data = try? Data(contentsOf: avatarURL),
              let preparedData = AvatarImageProcessor.prepare(data),
              let savedURL = localStore.saveAvatarData(preparedData, for: profile.id, fileExtension: AvatarImageProcessor.fileExtension) else {
            return
        }
        profile.avatarURL = savedURL
    }
}

