//
//  ProfileManager.swift
//  dinIslam
//
//  Created by GPT-5 Codex on 09.11.25.
//

import AuthenticationServices
import Foundation

@MainActor
@Observable
final class ProfileManager {
    enum SyncState: Equatable {
        case idle
        case syncing
        case failed(String)
    }

    var profile: UserProfile
    var syncState: SyncState = .idle
    var isLoading = false
    var errorMessage: String?
    var lastRecommendations: [LearningRecommendation] = []

    var isSignedIn: Bool {
        profile.authMethod != .anonymous
    }

    var displayName: String {
        // Сначала используем пользовательское имя, если оно задано
        if let customName = profile.customDisplayName, !customName.isEmpty {
            return customName
        }
        
        // Затем пытаемся использовать fullName
        if let fullName = profile.fullName, !fullName.isEmpty {
            return fullName
        }
        
        // Если fullName нет, используем email (если он не приватный)
        if let email = profile.email, !isPrivateEmail(email) {
            return email
        }
        
        // В последнюю очередь показываем анонимного пользователя
        return NSLocalizedString("profile.anonymous", comment: "Anonymous user placeholder")
    }

    var email: String? {
        profile.email
    }
    
    func isPrivateEmail(_ email: String) -> Bool {
        // Apple Sign In использует приватные relay адреса с доменом @privaterelay.appleid.com
        // Эти адреса не должны отображаться пользователю, если он выбрал скрыть email
        return email.contains("@privaterelay.appleid.com") || 
               email.contains("@icloud.com") && email.hasPrefix("no-reply")
    }

    var recommendations: [LearningRecommendation] {
        profile.progress.recommendations
    }

    var progress: ProfileProgress {
        profile.progress
    }

    @ObservationIgnored private let localStore: ProfileLocalStore
    @ObservationIgnored private let cloudService: CloudKitProfileService
    @ObservationIgnored private let adaptiveEngine: AdaptiveLearningEngine
    @ObservationIgnored private let statsManager: StatsManager
    @ObservationIgnored private let examStatisticsManager: ExamStatisticsManager
    
    // Services
    @ObservationIgnored private let authService: ProfileAuthService
    @ObservationIgnored private let syncService: ProfileSyncService
    @ObservationIgnored private let mergeService: ProfileMergeService
    @ObservationIgnored private let avatarManager: ProfileAvatarManager
    @ObservationIgnored private let progressBuilder: ProfileProgressBuilder

    init(
        localStore localStoreOverride: ProfileLocalStore? = nil,
        cloudService cloudServiceOverride: CloudKitProfileService? = nil,
        adaptiveEngine adaptiveEngineOverride: AdaptiveLearningEngine? = nil,
        statsManager: StatsManager,
        examStatisticsManager: ExamStatisticsManager
    ) {
        let resolvedLocalStore: ProfileLocalStore
        if let override = localStoreOverride {
            resolvedLocalStore = override
        } else {
            resolvedLocalStore = ProfileLocalStore()
        }

        let resolvedCloudService: CloudKitProfileService
        if let override = cloudServiceOverride {
            resolvedCloudService = override
        } else {
            resolvedCloudService = CloudKitProfileService(localStore: resolvedLocalStore)
        }

        let resolvedAdaptiveEngine: AdaptiveLearningEngine
        if let override = adaptiveEngineOverride {
            resolvedAdaptiveEngine = override
        } else {
            resolvedAdaptiveEngine = AdaptiveLearningEngine()
        }

        self.localStore = resolvedLocalStore
        self.cloudService = resolvedCloudService
        self.adaptiveEngine = resolvedAdaptiveEngine
        self.statsManager = statsManager
        self.examStatisticsManager = examStatisticsManager

        // Initialize services
        self.mergeService = ProfileMergeService(adaptiveEngine: resolvedAdaptiveEngine)
        self.avatarManager = ProfileAvatarManager(localStore: resolvedLocalStore)
        self.progressBuilder = ProfileProgressBuilder(
            adaptiveEngine: resolvedAdaptiveEngine,
            statsManager: statsManager,
            examStatisticsManager: examStatisticsManager
        )
        self.syncService = ProfileSyncService(
            cloudService: resolvedCloudService,
            localStore: resolvedLocalStore,
            mergeService: mergeService,
            avatarManager: avatarManager
        )
        self.authService = ProfileAuthService()

        if let storedProfile = resolvedLocalStore.loadCurrentProfile() {
            profile = storedProfile
        } else {
            profile = resolvedLocalStore.loadOrCreateAnonymousProfile()
        }

        // Валидация аватара при загрузке профиля
        avatarManager.validateAvatar(profile: &profile)
        localStore.saveProfile(profile)

        self.statsManager.profileSyncDelegate = self
        self.examStatisticsManager.profileSyncDelegate = self

        progressBuilder.rebuildProgressFromLocalStats(profile: &profile)
        localStore.saveProfile(profile)

        if profile.authMethod != .anonymous {
            Task {
                await refreshFromCloud(mergeStrategy: .newest)
            }
        }
    }

    // MARK: - Sign In with Apple
    func prepareSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        authService.prepareSignInRequest(request)
    }

    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        authService.handleSignInResult(
            result,
            onSuccess: { [weak self] credential in
                await self?.handleAppleCredential(credential)
            },
            onFailure: { [weak self] message in
                self?.errorMessage = message
                self?.syncState = .failed(message)
            }
        )
    }

    func signOut() {
        guard isSignedIn else { return }
        let signedInProfileId = profile.id
        
        // Сохраняем данные из ProfileProgress в локальные StatsManager перед выходом
        progressBuilder.syncProgressToLocalStats(profile: profile)
        
        // Переключаемся на анонимный профиль
        profile = localStore.loadOrCreateAnonymousProfile()
        
        // Восстанавливаем локальные данные в новый анонимный профиль
        progressBuilder.rebuildProgressFromLocalStats(profile: &profile)
        
        localStore.saveProfile(profile)
        syncState = .idle
        errorMessage = nil
        localStore.deleteAvatar(for: signedInProfileId)
    }

    func resetProfileData() async {
        isLoading = true
        syncService.cancelSync()
        let profileId = profile.id
        errorMessage = nil

        statsManager.resetStats()
        examStatisticsManager.resetStatistics()
        lastRecommendations = []
        profile.progress = ProfileProgress()
        profile.avatarURL = nil
        profile.metadata.updatedAt = Date()
        profile.metadata.lastSyncedAt = nil
        localStore.deleteAvatar(for: profileId)
        progressBuilder.rebuildProgressFromLocalStats(profile: &profile)
        localStore.saveProfile(profile)

        if isSignedIn {
            do {
                try await cloudService.deleteProfile(with: profileId)
                await performSync()
            } catch {
                let friendlyMessage = ProfileErrorHandler.userFriendlyErrorMessage(from: error)
                errorMessage = friendlyMessage
                syncState = .failed(friendlyMessage)
            }
        } else {
            syncState = .idle
        }

        isLoading = false
    }

    func updateAvatar(with data: Data, fileExtension: String = "dat") async {
        guard avatarManager.updateAvatar(profile: &profile, data: data, fileExtension: fileExtension) else {
            return
        }
        localStore.saveProfile(profile)
        if isSignedIn {
            await performSync()
        }
    }

    func deleteAvatar() async {
        avatarManager.deleteAvatar(profile: &profile)
        localStore.saveProfile(profile)
        if isSignedIn {
            await performSync()
        }
    }
    
    func updateDisplayName(_ newName: String?) async {
        let trimmedName = newName?.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.customDisplayName = trimmedName?.isEmpty == false ? trimmedName : nil
        profile.metadata.updatedAt = Date()
        localStore.saveProfile(profile)
        if isSignedIn {
            await performSync()
        }
    }

    func validateAvatar() {
        avatarManager.validateAvatar(profile: &profile)
        localStore.saveProfile(profile)
    }

    // MARK: - Sync Management
    func refreshFromCloud(mergeStrategy: ProfileMergeStrategy = .newest) async {
        let currentProfile = profile
        await syncService.refreshFromCloud(
            profile: currentProfile,
            mergeStrategy: mergeStrategy,
            onSuccess: { [weak self] updatedProfile in
                self?.profile = updatedProfile
                self?.syncState = .idle
                self?.errorMessage = nil
            },
            onError: { [weak self] message in
                self?.errorMessage = message
                self?.syncState = .failed(message)
            }
        )
    }

    private func scheduleSync() {
        let currentProfile = profile
        syncService.scheduleSync(
            profile: currentProfile,
            isSignedIn: isSignedIn
        ) { [weak self] updatedProfile in
            guard let self = self, let updated = updatedProfile else { return }
            self.profile = updated
        }
    }

    private func performSync() async {
        syncState = .syncing
        let currentProfile = profile
        await syncService.performSync(
            profile: currentProfile,
            onSuccess: { [weak self] updatedProfile in
                self?.profile = updatedProfile
                self?.syncState = .idle
                self?.errorMessage = nil
            },
            onError: { [weak self] message in
                self?.errorMessage = message
                self?.syncState = .failed(message)
            }
        )
    }

    // MARK: - Private Helpers
    private func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        defer { isLoading = false }

        let userId = credential.user
        
        var signedInProfile = UserProfile(
            id: userId,
            authMethod: .signInWithApple,
            fullName: formattedName(from: credential.fullName) ?? profile.fullName,
            email: credential.email ?? profile.email,
            customDisplayName: profile.customDisplayName, // Сохраняем пользовательское имя
            localeIdentifier: Locale.current.identifier,
            avatarURL: profile.avatarURL,
            progress: ProfileProgress(),
            preferences: profile.preferences,
            metadata: UserProfile.Metadata(
                createdAt: profile.metadata.createdAt,
                updatedAt: Date(),
                lastSyncedAt: nil,
                lastDeviceIdentifier: UIDeviceIdentifierProvider.currentIdentifier()
            )
        )
        
        // Временно устанавливаем signedInProfile как текущий профиль для rebuildProgressFromLocalStats
        let originalProfile = profile
        profile = signedInProfile
        progressBuilder.rebuildProgressFromLocalStats(profile: &profile)
        signedInProfile = profile
        profile = originalProfile

        do {
            var hasRemoteProfile = false
            if let remoteProfile = try await cloudService.fetchProfile(for: userId) {
                // Объединяем локальные данные (уже в signedInProfile.progress) с удаленными
                signedInProfile = mergeService.mergeProfile(local: signedInProfile, remote: remoteProfile, strategy: .newest)
                hasRemoteProfile = true
            }

            profile = signedInProfile
            
            // Если есть удаленный профиль, обновляем локальные данные из объединенного профиля
            if hasRemoteProfile {
                progressBuilder.syncProgressToLocalStats(profile: profile)
            }
            // Если нет удаленного профиля, локальные данные уже перенесены в ProfileProgress выше
            
            // Валидация аватара после входа
            avatarManager.validateAvatar(profile: &profile)
            localStore.saveProfile(profile)
            await performSync()
            errorMessage = nil
        } catch {
            let friendlyMessage = ProfileErrorHandler.userFriendlyErrorMessage(from: error)
            errorMessage = friendlyMessage
            syncState = .failed(friendlyMessage)
        }
    }

    private func formattedName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let formatter = PersonNameComponentsFormatter()
        return formatter.string(from: components)
    }
    
    deinit {
        syncService.cancelSync()
    }
}

// MARK: - Delegates
extension ProfileManager: ProfileProgressSyncDelegate {
    func statsManager(_ manager: StatsManager, didRecord summary: QuizSessionSummary) {
        lastRecommendations = adaptiveEngine.applyQuizSummary(summary, to: &profile)
        localStore.saveProfile(profile)
        scheduleSync()
    }

    func statsManagerDidReset(_ manager: StatsManager) {
        progressBuilder.rebuildProgressFromLocalStats(profile: &profile)
        localStore.saveProfile(profile)
        scheduleSync()
    }
    
    func statsManagerDidUpdate(_ manager: StatsManager) {
        // Обновляем progress из локальных данных при изменении статистики (например, при исправлении ошибок)
        progressBuilder.rebuildProgressFromLocalStats(profile: &profile)
        localStore.saveProfile(profile)
        scheduleSync()
    }
}

extension ProfileManager: ProfileExamSyncDelegate {
    func examStatisticsManager(_ manager: ExamStatisticsManager, didRecord summary: ExamSessionSummary) {
        adaptiveEngine.applyExamSummary(summary, to: &profile)
        localStore.saveProfile(profile)
        scheduleSync()
    }

    func examStatisticsManagerDidReset(_ manager: ExamStatisticsManager) {
        progressBuilder.rebuildProgressFromLocalStats(profile: &profile)
        localStore.saveProfile(profile)
        scheduleSync()
    }
}
