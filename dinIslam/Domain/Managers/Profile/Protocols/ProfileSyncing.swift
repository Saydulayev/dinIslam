//
//  ProfileSyncing.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

protocol ProfileSyncing {
    func refreshFromCloud(
        profile: UserProfile,
        mergeStrategy: ProfileMergeStrategy,
        onSuccess: @escaping (UserProfile) -> Void,
        onError: @escaping (String) -> Void
    ) async
    
    func scheduleSync(
        profile: UserProfile,
        isSignedIn: Bool,
        onComplete: @escaping (UserProfile?) -> Void
    )
    
    func performSync(
        profile: UserProfile,
        onSuccess: @escaping (UserProfile) -> Void,
        onError: @escaping (String) -> Void
    ) async
    
    nonisolated func cancelSync()
}

