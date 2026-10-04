//
//  ProfileAvatarHandling.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

protocol ProfileAvatarHandling {
    func updateAvatar(
        profile: inout UserProfile,
        data: Data,
        fileExtension: String
    ) -> Bool
    
    func deleteAvatar(profile: inout UserProfile)
    
    func validateAvatar(profile: inout UserProfile)
}

