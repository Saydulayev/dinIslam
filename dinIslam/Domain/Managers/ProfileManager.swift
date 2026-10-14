//
//  ProfileManager.swift
//  dinIslam
//
//  Created by Saydulayev on 12.01.26.
//

import CloudKit
import Foundation
import UIKit

@MainActor
@Observable
final class ProfileManager {
    enum SyncState: Equatable {
        case idle
        case syncing
        case failed(String)
    }

    /// Вход в iCloud на устройстве: синхронизация включается автоматически, когда он доступен
    enum ICloudStatus: Equatable {
        case checking
        case available
        case noAccount
        case restricted
        case unavailable

        init(_ status: CKAccountStatus) {
            switch status {
            case .available: self = .available
            case .noAccount: self = .noAccount
            case .restricted: self = .restricted
            case .couldNotDetermine, .temporarilyUnavailable: self = .unavailable
            @unknown default: self = .unavailable
            }
        }
    }

    var profile: UserProfile
    var iCloudStatus: ICloudStatus = .checking
    var syncState: SyncState = .idle
    var isLoading = false
    var errorMessage: String?

    var isSyncEnabled: Bool {
        iCloudStatus == .available
    }

    var displayName: String {
        editableDisplayName.isEmpty ? "profile.noName".localized : editableDisplayName
    }

    /// Имя для поля редактирования, иначе пустая строка
    var editableDisplayName: String {
        profile.customDisplayName ?? ""
    }

    var needsDisplayName: Bool {
        editableDisplayName.isEmpty
    }

    @ObservationIgnored private let localStore: ProfileLocalStore
    @ObservationIgnored private let cloudService: CloudKitProfileService
    @ObservationIgnored private let syncService: ProgressSyncService
    @ObservationIgnored private let avatarService: ProfileAvatarHandling
    @ObservationIgnored private let statsManager: StatsManager
    @ObservationIgnored private let examStatisticsManager: ExamStatisticsManager
    @ObservationIgnored private let questionPoolProgressManager: QuestionPoolProgressManaging
    @ObservationIgnored private var scheduledSync: Task<Void, Never>?
    @ObservationIgnored private var isSyncRunning = false
    @ObservationIgnored private var needsAnotherSync = false
    @ObservationIgnored nonisolated(unsafe) private var observationTasks: [Task<Void, Never>] = []
    @ObservationIgnored nonisolated(unsafe) private var localChangeObserver: NSObjectProtocol?

    /// Пауза после изменения на устройстве: несколько изменений подряд уходят одной синхронизацией
    private let syncDebounce: Duration = .seconds(2)

    /// В модульных тестах приложение только запускает тесты: его синхронизация не должна
    /// реагировать на хранилища тестов и обращаться к iCloud симулятора
    private static let isUnitTestHost = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    init(
        localStore localStoreOverride: ProfileLocalStore? = nil,
        cloudService cloudServiceOverride: CloudKitProfileService? = nil,
        syncStateStore: LocalSyncStateStore? = nil,
        statsManager: StatsManager,
        examStatisticsManager: ExamStatisticsManager,
        achievementManager: AchievementManager,
        questionPoolProgressManager: QuestionPoolProgressManaging? = nil,
        avatarService: ProfileAvatarHandling? = nil
    ) {
        let localStore = localStoreOverride ?? ProfileLocalStore()
        let cloudService = cloudServiceOverride ?? CloudKitProfileService()
        let questionPoolProgressManager = questionPoolProgressManager ?? DefaultQuestionPoolProgressManager()

        self.localStore = localStore
        self.cloudService = cloudService
        self.statsManager = statsManager
        self.examStatisticsManager = examStatisticsManager
        self.questionPoolProgressManager = questionPoolProgressManager
        self.avatarService = avatarService ?? DefaultProfileAvatarService(
            avatarManager: ProfileAvatarManager(localStore: localStore)
        )
        self.syncService = ProgressSyncService(
            cloudService: cloudService,
            stateStore: syncStateStore ?? LocalSyncStateStore(),
            statsManager: statsManager,
            examStatisticsManager: examStatisticsManager,
            questionPoolProgressManager: questionPoolProgressManager,
            achievementManager: achievementManager
        )

        profile = localStore.loadOrCreateProfile()
        // Валидация аватара при загрузке профиля
        self.avatarService.validateAvatar(profile: &profile)
        localStore.saveProfile(profile)

        syncService.profileProvider = self
        startObserving()
    }

    nonisolated deinit {
        observationTasks.forEach { $0.cancel() }
        if let localChangeObserver {
            NotificationCenter.default.removeObserver(localChangeObserver)
        }
    }

    private func startObserving() {
        guard !Self.isUnitTestHost else { return }
        // Сброс должен начать новое поколение до следующего снимка, поэтому наблюдатель синхронный
        localChangeObserver = NotificationCenter.default.addObserver(
            forName: .syncedDataDidChange,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            let resetSections = SyncedDataChange.resetSections(from: notification)
            MainActor.assumeIsolated {
                self?.handleLocalChange(resetSections: resetSections)
            }
        }

        observationTasks = [
            Task { [weak self] in
                await self?.updateICloudStatus()
                // Вход в iCloud, выход или смена аккаунта в Настройках
                for await _ in NotificationCenter.default.notifications(named: .CKAccountChanged) {
                    await self?.updateICloudStatus()
                }
            },
            Task { [weak self] in
                // Изменения с других устройств подтягиваются при возвращении в приложение
                for await _ in NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification) {
                    await self?.syncNow()
                }
            }
        ]
    }

    // MARK: - iCloud
    /// Проверяет вход в iCloud; когда синхронизация становится доступной, сразу синхронизирует
    func updateICloudStatus() async {
        let wasSyncEnabled = isSyncEnabled
        do {
            iCloudStatus = ICloudStatus(try await cloudService.accountStatus())
        } catch {
            AppLogger.warning("Failed to get iCloud account status: \(error.localizedDescription)", category: AppLogger.data)
            iCloudStatus = .unavailable
        }

        if isSyncEnabled && !wasSyncEnabled {
            await syncNow()
        } else if !isSyncEnabled {
            scheduledSync?.cancel()
            syncState = .idle
            errorMessage = nil
        }
    }

    // MARK: - Sync
    /// Синхронизирует сейчас; запрос во время синхронизации выполнится сразу после неё
    func syncNow() async {
        guard isSyncEnabled else { return }
        guard !isSyncRunning else {
            needsAnotherSync = true
            return
        }

        isSyncRunning = true
        defer { isSyncRunning = false }
        repeat {
            needsAnotherSync = false
            syncState = .syncing
            do {
                try await syncService.sync()
                profile.metadata.lastSyncedAt = Date()
                localStore.saveProfile(profile)
                syncState = .idle
                errorMessage = nil
            } catch {
                let message = ProfileErrorHandler.userFriendlyErrorMessage(from: error)
                syncState = .failed(message)
                errorMessage = message
                return
            }
        } while needsAnotherSync && isSyncEnabled
    }

    private func scheduleSync() {
        guard isSyncEnabled else { return }
        scheduledSync?.cancel()
        scheduledSync = Task { [weak self, syncDebounce] in
            try? await Task.sleep(for: syncDebounce)
            guard !Task.isCancelled else { return }
            await self?.syncNow()
        }
    }

    private func handleLocalChange(resetSections: [SyncSection]) {
        if !resetSections.isEmpty {
            syncService.startNewEpoch(for: resetSections)
        }
        scheduleSync()
    }

    private func waitForRunningSync() async {
        scheduledSync?.cancel()
        while isSyncRunning {
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    // MARK: - Data
    /// Удаление всех данных: в iCloud и на устройстве (имя, фото, статистика, ошибки, прогресс, достижения).
    /// Другие устройства удалят данные при своей синхронизации. Синхронизация остаётся включённой.
    /// Если iCloud временно недоступен или запись не удалось сохранить, бросает ошибку и ничего не удаляет.
    func deleteAllData() async throws {
        isLoading = true
        defer { isLoading = false }
        await waitForRunningSync()

        let includeICloud: Bool
        switch try await cloudService.accountStatus() {
        case .available:
            includeICloud = true
        case .noAccount, .restricted:
            // Без входа в iCloud данных там нет
            includeICloud = false
        default:
            throw CloudKitProfileError.iCloudUnavailable
        }

        try await syncService.deleteAllData(includeICloud: includeICloud)
        profile.metadata.lastSyncedAt = includeICloud ? Date() : nil
        localStore.saveProfile(profile)
        syncState = .idle
        errorMessage = nil
    }

    /// Сброс статистики, ошибок, экзаменов и пройденных вопросов — на этом устройстве и на всех остальных.
    /// Имя, фото и достижения не меняются.
    func resetProfileData() async {
        isLoading = true
        defer { isLoading = false }
        await waitForRunningSync()
        errorMessage = nil

        statsManager.resetStats()
        examStatisticsManager.resetStatistics()
        questionPoolProgressManager.reset(version: 1)
        questionPoolProgressManager.setReviewMode(false, version: 1)

        scheduledSync?.cancel()
        await syncNow()
    }

    // MARK: - Name and Photo
    func updateAvatar(with data: Data) async {
        guard avatarService.updateAvatar(profile: &profile, data: data) else {
            return
        }
        profile.avatarUpdatedAt = .syncTimestamp
        localStore.saveProfile(profile)
        await syncNow()
    }

    func deleteAvatar() async {
        avatarService.deleteAvatar(profile: &profile)
        profile.avatarUpdatedAt = .syncTimestamp
        localStore.saveProfile(profile)
        await syncNow()
    }

    func updateDisplayName(_ newName: String?) async {
        let trimmedName = newName?.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.customDisplayName = trimmedName?.isEmpty == false ? trimmedName : nil
        profile.displayNameUpdatedAt = .syncTimestamp
        profile.metadata.updatedAt = Date()
        localStore.saveProfile(profile)
        await syncNow()
    }

    func validateAvatar() {
        avatarService.validateAvatar(profile: &profile)
        localStore.saveProfile(profile)
    }
}

// MARK: - SyncProfileProviding
extension ProfileManager: SyncProfileProviding {
    var syncDisplayName: Timestamped<String?> {
        Timestamped(value: profile.customDisplayName, updatedAt: profile.displayNameUpdatedAt)
    }

    var syncAvatar: Timestamped<String> {
        let hash = syncAvatarFileURL.flatMap { AvatarImageProcessor.fingerprint(ofFileAt: $0) } ?? ""
        return Timestamped(value: hash, updatedAt: profile.avatarUpdatedAt)
    }

    var syncAvatarFileURL: URL? {
        guard let url = profile.avatarURL, FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    func applySyncedDisplayName(_ displayName: Timestamped<String?>) {
        profile.customDisplayName = displayName.value
        profile.displayNameUpdatedAt = displayName.updatedAt
        localStore.saveProfile(profile)
    }

    func applySyncedAvatar(_ avatar: Timestamped<String>, data: Data?) {
        if avatar.value.isEmpty {
            localStore.deleteAvatar(for: profile.id)
            profile.avatarURL = nil
            profile.metadata.updatedAt = Date()
        } else if let data,
                  let savedURL = localStore.saveAvatarData(data, for: profile.id, fileExtension: AvatarImageProcessor.fileExtension) {
            profile.avatarURL = savedURL
            // Файл перезаписан по тому же пути: дата изменения обновляет картинку на экране
            profile.metadata.updatedAt = Date()
        }
        profile.avatarUpdatedAt = avatar.updatedAt
        localStore.saveProfile(profile)
    }

    func clearProfileForSync() {
        localStore.deleteAvatar(for: profile.id)
        profile.avatarURL = nil
        profile.customDisplayName = nil
        profile.displayNameUpdatedAt = .distantPast
        profile.avatarUpdatedAt = .distantPast
        profile.metadata.updatedAt = Date()
        localStore.saveProfile(profile)
    }
}
