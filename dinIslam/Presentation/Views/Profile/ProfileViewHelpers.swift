//
//  ProfileViewHelpers.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

enum ProfileViewHelpers {
    static func syncIcon(for state: ProfileManager.SyncState) -> String {
        switch state {
        case .idle:
            return "checkmark.circle.fill"
        case .syncing:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    static func syncColor(for state: ProfileManager.SyncState) -> Color {
        switch state {
        case .idle:
            return DesignTokens.Colors.statusGreen
        case .syncing:
            return DesignTokens.Colors.iconBlue
        case .failed:
            return DesignTokens.Colors.iconOrange
        }
    }

    static func syncMessage(
        for manager: ProfileManager,
        settingsManager: SettingsManager
    ) -> String {
        switch manager.syncState {
        case .idle:
            if let date = manager.profile.metadata.lastSyncedAt {
                let formatter = RelativeDateTimeFormatter()
                // Локаль по языку приложения, а не системы
                formatter.locale = Locale(identifier: settingsManager.settings.language.resolved == .english ? "en_US" : "ru_RU")
                
                let relativeTime = formatter.localizedString(for: date, relativeTo: Date())
                let formatString = "profile.sync.lastSync".localized
                return String(format: formatString, relativeTime)
            }
            return "profile.sync.never".localized
        case .syncing:
            return "profile.sync.inProgress".localized
        case .failed(let message):
            // Message is already user-friendly, no need to format
            return message
        }
    }

    static func avatarExists(for manager: ProfileManager) -> Bool {
        guard let url = manager.profile.avatarURL else { return false }
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: url.path)
    }

    #if os(iOS)
    /// Чтение и декодирование файла уходит с главного потока
    static func loadAvatarImage(from url: URL?) async -> Image? {
        guard let url else { return nil }
        let uiImage = await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: url.path)?.preparingForDisplay()
        }.value
        return uiImage.map { Image(uiImage: $0) }
    }
    #endif
}

