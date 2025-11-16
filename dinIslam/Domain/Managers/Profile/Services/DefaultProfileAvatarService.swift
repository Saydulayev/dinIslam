//
//  DefaultProfileAvatarService.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class DefaultProfileAvatarService: ProfileAvatarHandling {
    private let avatarManager: ProfileAvatarManager
    
    init(avatarManager: ProfileAvatarManager) {
        self.avatarManager = avatarManager
    }
    
    func updateAvatar(
        profile: inout UserProfile,
        data: Data,
        fileExtension: String
    ) -> Bool {
        return avatarManager.updateAvatar(
            profile: &profile,
            data: data,
            fileExtension: fileExtension
        )
    }
    
    func deleteAvatar(profile: inout UserProfile) {
        avatarManager.deleteAvatar(profile: &profile)
    }
    
    func validateAvatar(profile: inout UserProfile) {
        avatarManager.validateAvatar(profile: &profile)
    }
}

