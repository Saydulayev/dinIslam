//
//  DefaultProfileSyncService.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

final class DefaultProfileSyncService: ProfileSyncing {
    private let syncService: ProfileSyncService
    
    init(syncService: ProfileSyncService) {
        self.syncService = syncService
    }
    
    func refreshFromCloud(
        profile: UserProfile,
        mergeStrategy: ProfileMergeStrategy,
        onSuccess: @escaping (UserProfile) -> Void,
        onError: @escaping (String) -> Void
    ) async {
        await syncService.refreshFromCloud(
            profile: profile,
            mergeStrategy: mergeStrategy,
            onSuccess: onSuccess,
            onError: onError
        )
    }
    
    func scheduleSync(
        profile: UserProfile,
        isSignedIn: Bool,
        onComplete: @escaping (UserProfile?) -> Void
    ) {
        syncService.scheduleSync(
            profile: profile,
            isSignedIn: isSignedIn,
            onComplete: onComplete
        )
    }
    
    func performSync(
        profile: UserProfile,
        onSuccess: @escaping (UserProfile) -> Void,
        onError: @escaping (String) -> Void
    ) async {
        await syncService.performSync(
            profile: profile,
            onSuccess: onSuccess,
            onError: onError
        )
    }
    
    nonisolated func cancelSync() {
        syncService.cancelSync()
    }
}

