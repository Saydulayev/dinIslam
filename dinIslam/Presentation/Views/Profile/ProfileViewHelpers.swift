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
                // Устанавливаем локаль в зависимости от текущего языка приложения
                let currentLanguage = settingsManager.settings.language == .system ? 
                    (Locale.current.language.languageCode?.identifier ?? "ru") :
                    settingsManager.settings.language.rawValue
                formatter.locale = Locale(identifier: currentLanguage == "en" ? "en_US" : "ru_RU")
                
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
    static func avatarImage(for manager: ProfileManager) -> Image? {
        guard let url = manager.profile.avatarURL,
              FileManager.default.fileExists(atPath: url.path),
              let uiImage = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
    #else
    static func avatarImage(for manager: ProfileManager) -> Image? {
        guard let url = manager.profile.avatarURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let nsImage = NSImage(data: data) else {
            return nil
        }
        return Image(nsImage: nsImage)
    }
    #endif
}

