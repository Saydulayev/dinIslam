//
//  ProfileSyncService.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import CloudKit
import Foundation

final class ProfileSyncService {
    private let cloudService: CloudKitProfileService
    private let localStore: ProfileLocalStore
    private let mergeService: ProfileMergeService
    private let avatarManager: ProfileAvatarManager
    
    nonisolated(unsafe) private var syncTask: Task<Void, Never>?
    private var conflictResolutionAttempts: Int = 0
    private var isSyncing: Bool = false
    private let maxConflictResolutionAttempts = 1
    
    init(
        cloudService: CloudKitProfileService,
        localStore: ProfileLocalStore,
        mergeService: ProfileMergeService,
        avatarManager: ProfileAvatarManager
    ) {
        self.cloudService = cloudService
        self.localStore = localStore
        self.mergeService = mergeService
        self.avatarManager = avatarManager
    }
    
    func refreshFromCloud(
        profile: UserProfile,
        mergeStrategy: ProfileMergeStrategy = .newest,
        onSuccess: (UserProfile) -> Void,
        onError: (String) -> Void
    ) async {
        guard profile.authMethod != .anonymous else { return }
        do {
            if let remoteProfile = try await cloudService.fetchProfile(for: profile.id) {
                var updatedProfile = mergeService.mergeProfile(local: profile, remote: remoteProfile, strategy: mergeStrategy)
                updatedProfile.metadata.lastSyncedAt = Date()
                avatarManager.validateAvatar(profile: &updatedProfile)
                localStore.saveProfile(updatedProfile)
                onSuccess(updatedProfile)
            }
        } catch {
            let friendlyMessage = ProfileErrorHandler.userFriendlyErrorMessage(from: error)
            onError(friendlyMessage)
        }
    }

    func scheduleSync(profile: UserProfile, isSignedIn: Bool, onComplete: @escaping (UserProfile?) -> Void) {
        localStore.saveProfile(profile)
        guard isSignedIn else { return }

        syncTask?.cancel()
        syncTask = Task { [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds debounce
            
            // Проверяем отмену после sleep
            if Task.isCancelled {
                return
            }
            
            await self.performSync(
                profile: profile,
                onSuccess: { updatedProfile in
                    onComplete(updatedProfile)
                },
                onError: { _ in
                    onComplete(nil)
                }
            )
        }
    }

    func performSync(
        profile: UserProfile,
        onSuccess: (UserProfile) -> Void,
        onError: (String) -> Void
    ) async {
        guard profile.authMethod != .anonymous else { return }
        
        // Проверяем, не отменен ли Task
        if Task.isCancelled {
            return
        }
        
        // Предотвращаем множественные одновременные синхронизации
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // Prepare a copy for saving, but do NOT set lastSyncedAt yet (only after successful save)
            var profileToSync = profile
            profileToSync.metadata.updatedAt = Date()
            let savedProfile = try await cloudService.saveProfile(profileToSync)
            
            // Проверяем отмену после async операции
            if Task.isCancelled {
                return
            }
            
            var finalProfile = savedProfile
            // Set lastSyncedAt only after successful save
            finalProfile.metadata.lastSyncedAt = Date()
            // Валидация аватара после синхронизации
            avatarManager.validateAvatar(profile: &finalProfile)
            localStore.saveProfile(finalProfile)
            conflictResolutionAttempts = 0 // Сбрасываем счетчик при успехе
            onSuccess(finalProfile)
        } catch {
            // Проверяем отмену после async операции
            if Task.isCancelled {
                return
            }
            
            // Detect conflict (serverRecordChanged or oplock text) and resolve once
            let isConflict: Bool = {
                if let ck = error as? CKError, ck.code == .serverRecordChanged { return true }
                let desc = error.localizedDescription.lowercased()
                return desc.contains("oplock") || desc.contains("server record changed")
            }()

            if isConflict && conflictResolutionAttempts < maxConflictResolutionAttempts {
                conflictResolutionAttempts += 1
                do {
                    // Fetch latest server profile
                    if let serverProfile = try await cloudService.fetchProfile(for: profile.id) {
                        // Проверяем отмену после async операции
                        if Task.isCancelled {
                            return
                        }
                        
                        // Merge local vs server using your strategy (newest is appropriate)
                        let merged = mergeService.mergeProfile(local: profile, remote: serverProfile, strategy: .newest)
                        var mergedToSave = merged
                        // updatedAt now to reflect this reconciliation
                        mergedToSave.metadata.updatedAt = Date()
                        // Try saving merged profile once
                        let savedMerged = try await cloudService.saveProfile(mergedToSave)
                        
                        // Проверяем отмену после async операции
                        if Task.isCancelled {
                            return
                        }
                        
                        var finalProfile = savedMerged
                        finalProfile.metadata.lastSyncedAt = Date()
                        avatarManager.validateAvatar(profile: &finalProfile)
                        localStore.saveProfile(finalProfile)
                        conflictResolutionAttempts = 0 // Сбрасываем при успехе
                        onSuccess(finalProfile)
                        return
                    } else {
                        // No server profile - не пытаемся сохранять снова, просто показываем ошибку
                        let friendlyMessage = ProfileErrorHandler.userFriendlyErrorMessage(from: error)
                        onError(friendlyMessage)
                        conflictResolutionAttempts = 0
                    }
                } catch {
                    // Если разрешение конфликта не удалось, показываем ошибку и не пытаемся снова
                    let friendlyMessage = ProfileErrorHandler.userFriendlyErrorMessage(from: error)
                    onError(friendlyMessage)
                    conflictResolutionAttempts = 0
                }
            } else {
                // Превышен лимит попыток или это не конфликт - показываем ошибку
                let friendlyMessage = ProfileErrorHandler.userFriendlyErrorMessage(from: error)
                onError(friendlyMessage)
                // Сбрасываем счетчик только если это не конфликт
                if !isConflict {
                    conflictResolutionAttempts = 0
                }
            }
        }
    }
    
    nonisolated func cancelSync() {
        syncTask?.cancel()
    }
}

