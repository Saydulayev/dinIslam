//
//  ProfileManager.swift
//  dinIslam
//
//  Created by GPT-5 Codex on 09.11.25.
//

import AuthenticationServices
import CloudKit
import CryptoKit
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
    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private var currentNonce: String?
    @ObservationIgnored private var conflictResolutionAttempts: Int = 0
    @ObservationIgnored private var isSyncing: Bool = false
    private let maxConflictResolutionAttempts = 1 // Разрешаем конфликт только один раз

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

        if let storedProfile = resolvedLocalStore.loadCurrentProfile() {
            profile = storedProfile
        } else {
            profile = resolvedLocalStore.loadOrCreateAnonymousProfile()
        }

        // Валидация аватара при загрузке профиля
        validateAvatar()

        self.statsManager.profileSyncDelegate = self
        self.examStatisticsManager.profileSyncDelegate = self

        rebuildProgressFromLocalStats()

        if profile.authMethod != .anonymous {
            Task {
                await refreshFromCloud(mergeStrategy: .newest)
            }
        }
    }

    // MARK: - Sign In with Apple
    func prepareSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = NSLocalizedString("profile.signin.invalidCredential", comment: "Invalid credential")
                return
            }
            Task {
                await handleAppleCredential(credential)
            }
        case .failure(let error):
            let friendlyMessage = userFriendlyErrorMessage(from: error)
            errorMessage = friendlyMessage
            syncState = .failed(friendlyMessage)
        }
    }

    func signOut() {
        guard isSignedIn else { return }
        let signedInProfileId = profile.id
        
        // Сохраняем данные из ProfileProgress в локальные StatsManager перед выходом
        syncProgressToLocalStats()
        
        // Переключаемся на анонимный профиль
        profile = localStore.loadOrCreateAnonymousProfile()
        
        // Восстанавливаем локальные данные в новый анонимный профиль
        rebuildProgressFromLocalStats()
        
        localStore.saveProfile(profile)
        syncState = .idle
        errorMessage = nil
        localStore.deleteAvatar(for: signedInProfileId)
    }

    func resetProfileData() async {
        isLoading = true
        syncTask?.cancel()
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
        rebuildProgressFromLocalStats()
        localStore.saveProfile(profile)

        if isSignedIn {
            do {
                try await cloudService.deleteProfile(with: profileId)
                await performSync()
            } catch {
                let friendlyMessage = userFriendlyErrorMessage(from: error)
                errorMessage = friendlyMessage
                syncState = .failed(friendlyMessage)
            }
        } else {
            syncState = .idle
        }

        isLoading = false
    }

    func updateAvatar(with data: Data, fileExtension: String = "dat") async {
        guard let savedURL = localStore.saveAvatarData(data, for: profile.id, fileExtension: fileExtension) else {
            return
        }
        profile.avatarURL = savedURL
        profile.metadata.updatedAt = Date()
        localStore.saveProfile(profile)
        if isSignedIn {
            await performSync()
        }
    }

    func deleteAvatar() async {
        guard profile.avatarURL != nil else { return }
        localStore.deleteAvatar(for: profile.id)
        profile.avatarURL = nil
        profile.metadata.updatedAt = Date()
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
        // Проверяем существование файла аватара
        if let avatarURL = profile.avatarURL {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: avatarURL.path) {
                // Файл не существует, пытаемся найти его в локальном хранилище
                if let existingAvatar = localStore.loadAvatar(for: profile.id) {
                    profile.avatarURL = existingAvatar
                    localStore.saveProfile(profile)
                } else {
                    // Файл не найден, очищаем avatarURL
                    profile.avatarURL = nil
                    localStore.saveProfile(profile)
                }
            }
        } else {
            // Если avatarURL отсутствует, но файл существует, восстанавливаем ссылку
            if let existingAvatar = localStore.loadAvatar(for: profile.id) {
                profile.avatarURL = existingAvatar
                localStore.saveProfile(profile)
            }
        }
    }

    // MARK: - Sync Management
    func refreshFromCloud(mergeStrategy: ProfileMergeStrategy = .newest) async {
        guard isSignedIn else { return }
        do {
            if let remoteProfile = try await cloudService.fetchProfile(for: profile.id) {
                profile = mergeProfile(local: profile, remote: remoteProfile, strategy: mergeStrategy)
                profile.metadata.lastSyncedAt = Date()
                // Валидация аватара после синхронизации
                validateAvatar()
                localStore.saveProfile(profile)
            }
        } catch {
            let friendlyMessage = userFriendlyErrorMessage(from: error)
            errorMessage = friendlyMessage
            syncState = .failed(friendlyMessage)
        }
    }

    private func scheduleSync() {
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
            
            await self.performSync()
        }
    }

    private func performSync() async {
        guard isSignedIn else { return }
        
        // Проверяем, не отменен ли Task
        if Task.isCancelled {
            return
        }
        
        // Предотвращаем множественные одновременные синхронизации
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        syncState = .syncing
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
            profile = finalProfile
            // Валидация аватара после синхронизации
            validateAvatar()
            localStore.saveProfile(profile)
            syncState = .idle
            errorMessage = nil
            conflictResolutionAttempts = 0 // Сбрасываем счетчик при успехе
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
                        let merged = mergeProfile(local: profile, remote: serverProfile, strategy: .newest)
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
                        profile = finalProfile
                        validateAvatar()
                        localStore.saveProfile(profile)
                        syncState = .idle
                        errorMessage = nil
                        conflictResolutionAttempts = 0 // Сбрасываем при успехе
                        return
                    } else {
                        // No server profile - не пытаемся сохранять снова, просто показываем ошибку
                        let friendlyMessage = userFriendlyErrorMessage(from: error)
                        errorMessage = friendlyMessage
                        syncState = .failed(friendlyMessage)
                        conflictResolutionAttempts = 0
                    }
                } catch {
                    // Если разрешение конфликта не удалось, показываем ошибку и не пытаемся снова
                    let friendlyMessage = userFriendlyErrorMessage(from: error)
                    errorMessage = friendlyMessage
                    syncState = .failed(friendlyMessage)
                    conflictResolutionAttempts = 0
                }
            } else {
                // Превышен лимит попыток или это не конфликт - показываем ошибку
                let friendlyMessage = userFriendlyErrorMessage(from: error)
                errorMessage = friendlyMessage
                syncState = .failed(friendlyMessage)
                // Сбрасываем счетчик только если это не конфликт
                if !isConflict {
                    conflictResolutionAttempts = 0
                }
            }
        }
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
        rebuildProgressFromLocalStats()
        signedInProfile = profile
        profile = originalProfile

        do {
            var hasRemoteProfile = false
            if let remoteProfile = try await cloudService.fetchProfile(for: userId) {
                // Объединяем локальные данные (уже в signedInProfile.progress) с удаленными
                signedInProfile = mergeProfile(local: signedInProfile, remote: remoteProfile, strategy: .newest)
                hasRemoteProfile = true
            }

            profile = signedInProfile
            
            // Если есть удаленный профиль, обновляем локальные данные из объединенного профиля
            if hasRemoteProfile {
                syncProgressToLocalStats()
            }
            // Если нет удаленного профиля, локальные данные уже перенесены в ProfileProgress выше
            
            // Валидация аватара после входа
            validateAvatar()
            localStore.saveProfile(profile)
            await performSync()
            errorMessage = nil
        } catch {
            let friendlyMessage = userFriendlyErrorMessage(from: error)
            errorMessage = friendlyMessage
            syncState = .failed(friendlyMessage)
        }
    }

    private func rebuildProgressFromLocalStats() {
        var progress = profile.progress
        let stats = statsManager.stats
        let examStats = examStatisticsManager.statistics

        progress.totalQuestionsAnswered = stats.totalQuestionsStudied
        progress.correctAnswers = stats.correctAnswers
        progress.incorrectAnswers = stats.incorrectAnswers
        progress.correctedMistakes = stats.correctedMistakes
        progress.currentStreak = stats.currentStreak
        progress.longestStreak = stats.longestStreak
        progress.averageQuizScore = stats.averageRecentScore
        progress.lastActivityAt = stats.lastQuizDate

        progress.examsTaken = examStats.totalExamsCompleted
        progress.examsPassed = examStats.examsPassed

        progress.difficultyStats = stats.difficultyStats.compactMap { key, value in
            guard let difficulty = Difficulty(rawValue: key) else { return nil }
            return DifficultyPerformance(
                difficulty: difficulty,
                correctAnswers: value.correctAnswers,
                totalAnswers: value.totalAnswers,
                adaptiveScore: value.adaptiveScore,
                masteryLevel: masteryLevel(for: value.adaptiveScore)
            )
        }

        progress.topicProgress = stats.topicStats.map { key, value in
            TopicProgress(
                topicId: key,
                displayName: key,
                correctAnswers: value.correctAnswers,
                totalAnswers: value.totalAnswers,
                masteryLevel: masteryLevel(for: value.accuracy),
                streak: value.streak,
                recommendedDifficulty: recommendedDifficulty(for: masteryLevel(for: value.accuracy)),
                lastActivityAt: value.lastUpdated
            )
        }

        progress.quizHistory = stats.recentQuizResults.map { record in
            let correctCount = Int((record.percentage / 100.0) * Double(record.questionsCount))
            return QuizHistoryEntry(
                date: record.date,
                percentage: record.percentage,
                correctAnswers: correctCount,
                totalQuestions: record.questionsCount,
                difficultyBreakdown: [:],
                topicBreakdown: [:]
            )
        }

        progress.examHistory = progress.examHistory.filter { entry in
            examStats.lastExamDate == nil || entry.date <= (examStats.lastExamDate ?? entry.date)
        }

        progress.masteryLevel = adaptiveEngine.computeOverallMastery(
            averageScore: progress.averageQuizScore,
            streak: progress.currentStreak
        )
        progress.recommendations = adaptiveEngine.generateRecommendations(for: progress)

        profile.progress = progress
        profile.metadata.updatedAt = Date()
    }
    
    // MARK: - Sync Progress to Local Stats
    private func syncProgressToLocalStats() {
        // Переносим данные из ProfileProgress обратно в локальные StatsManager и ExamStatisticsManager
        statsManager.updateFromProfileProgress(profile.progress, quizHistory: profile.progress.quizHistory)
        examStatisticsManager.updateFromProfileProgress(profile.progress, examHistory: profile.progress.examHistory)
    }

    private func mergeProfile(local: UserProfile, remote: UserProfile, strategy: ProfileMergeStrategy) -> UserProfile {
        var merged = remote

        switch strategy {
        case .preferLocal:
            merged.fullName = local.fullName ?? remote.fullName
            merged.email = local.email ?? remote.email
            merged.customDisplayName = local.customDisplayName ?? remote.customDisplayName
            merged.preferences = mergePreferences(remote: remote.preferences, local: local.preferences, preferLocal: true)
            merged.progress = mergeProgress(remote: remote.progress, local: local.progress, preferLocal: true)
            merged.avatarURL = local.avatarURL ?? merged.avatarURL
        case .preferRemote:
            merged.fullName = remote.fullName ?? local.fullName
            merged.email = remote.email ?? local.email
            merged.customDisplayName = remote.customDisplayName ?? local.customDisplayName
            merged.preferences = mergePreferences(remote: remote.preferences, local: local.preferences, preferLocal: false)
            merged.progress = mergeProgress(remote: remote.progress, local: local.progress, preferLocal: false)
            merged.avatarURL = remote.avatarURL ?? local.avatarURL
        case .newest:
            let preferLocal = (local.metadata.updatedAt > remote.metadata.updatedAt)
            // Сохраняем fullName, email и customDisplayName, предпочитая непустые значения
            merged.fullName = preferLocal ? 
                (local.fullName ?? remote.fullName) : 
                (remote.fullName ?? local.fullName)
            merged.email = preferLocal ? 
                (local.email ?? remote.email) : 
                (remote.email ?? local.email)
            merged.customDisplayName = preferLocal ? 
                (local.customDisplayName ?? remote.customDisplayName) : 
                (remote.customDisplayName ?? local.customDisplayName)
            merged.preferences = mergePreferences(remote: remote.preferences, local: local.preferences, preferLocal: preferLocal)
            merged.progress = mergeProgress(remote: remote.progress, local: local.progress, preferLocal: preferLocal)
            merged.avatarURL = preferLocal
                ? (local.avatarURL ?? remote.avatarURL)
                : (remote.avatarURL ?? local.avatarURL)
        }

        merged.metadata.updatedAt = Date()
        merged.metadata.lastSyncedAt = Date()
        merged.metadata.lastDeviceIdentifier = UIDeviceIdentifierProvider.currentIdentifier()
        return merged
    }

    private func mergePreferences(remote: ProfilePreferences, local: ProfilePreferences, preferLocal: Bool) -> ProfilePreferences {
        ProfilePreferences(
            preferredDifficulty: preferLocal ? (local.preferredDifficulty ?? remote.preferredDifficulty) : (remote.preferredDifficulty ?? local.preferredDifficulty),
            dailyGoal: preferLocal ? local.dailyGoal : remote.dailyGoal,
            notificationsEnabled: preferLocal ? local.notificationsEnabled : remote.notificationsEnabled,
            syncedSettings: preferLocal ? local.syncedSettings : remote.syncedSettings,
            preferredStudyTopics: preferLocal ? (local.preferredStudyTopics.isEmpty ? remote.preferredStudyTopics : local.preferredStudyTopics) : (remote.preferredStudyTopics.isEmpty ? local.preferredStudyTopics : remote.preferredStudyTopics)
        )
    }

    private func mergeProgress(remote: ProfileProgress, local: ProfileProgress, preferLocal: Bool) -> ProfileProgress {
        var merged = remote

        if preferLocal {
            merged.totalQuestionsAnswered = max(remote.totalQuestionsAnswered, local.totalQuestionsAnswered)
            merged.correctAnswers = max(remote.correctAnswers, local.correctAnswers)
            merged.incorrectAnswers = max(remote.incorrectAnswers, local.incorrectAnswers)
            merged.correctedMistakes = max(remote.correctedMistakes, local.correctedMistakes)
            merged.examsTaken = max(remote.examsTaken, local.examsTaken)
            merged.examsPassed = max(remote.examsPassed, local.examsPassed)
            merged.currentStreak = max(remote.currentStreak, local.currentStreak)
            merged.longestStreak = max(remote.longestStreak, local.longestStreak)
            merged.averageQuizScore = max(remote.averageQuizScore, local.averageQuizScore)
        } else {
            merged.totalQuestionsAnswered = max(remote.totalQuestionsAnswered, local.totalQuestionsAnswered)
            merged.correctAnswers = max(remote.correctAnswers, local.correctAnswers)
            merged.incorrectAnswers = max(remote.incorrectAnswers, local.incorrectAnswers)
            merged.correctedMistakes = max(remote.correctedMistakes, local.correctedMistakes)
            merged.examsTaken = max(remote.examsTaken, local.examsTaken)
            merged.examsPassed = max(remote.examsPassed, local.examsPassed)
            merged.currentStreak = max(remote.currentStreak, local.currentStreak)
            merged.longestStreak = max(remote.longestStreak, local.longestStreak)
            merged.averageQuizScore = max(remote.averageQuizScore, local.averageQuizScore)
        }

        merged.difficultyStats = mergeDifficultyStats(remote: remote.difficultyStats, local: local.difficultyStats)
        merged.topicProgress = mergeTopicProgress(remote: remote.topicProgress, local: local.topicProgress)
        merged.quizHistory = mergeQuizHistory(remote: remote.quizHistory, local: local.quizHistory)
        merged.examHistory = mergeExamHistory(remote: remote.examHistory, local: local.examHistory)
        let latestActivity = max(remote.lastActivityAt ?? .distantPast, local.lastActivityAt ?? .distantPast)
        merged.lastActivityAt = latestActivity == .distantPast ? nil : latestActivity
        merged.recommendations = adaptiveEngine.generateRecommendations(for: merged)
        merged.masteryLevel = adaptiveEngine.computeOverallMastery(
            averageScore: merged.averageQuizScore,
            streak: merged.currentStreak
        )
        return merged
    }

    private func mergeDifficultyStats(remote: [DifficultyPerformance], local: [DifficultyPerformance]) -> [DifficultyPerformance] {
        var dictionary: [Difficulty: DifficultyPerformance] = [:]
        for stat in remote {
            dictionary[stat.difficulty] = stat
        }
        for stat in local {
            if var existing = dictionary[stat.difficulty] {
                existing.totalAnswers = max(existing.totalAnswers, stat.totalAnswers)
                existing.correctAnswers = max(existing.correctAnswers, stat.correctAnswers)
                existing.adaptiveScore = max(existing.adaptiveScore, stat.adaptiveScore)
                existing.masteryLevel = maxMastery(existing.masteryLevel, stat.masteryLevel)
                dictionary[stat.difficulty] = existing
            } else {
                dictionary[stat.difficulty] = stat
            }
        }
        return Array(dictionary.values)
    }

    private func mergeTopicProgress(remote: [TopicProgress], local: [TopicProgress]) -> [TopicProgress] {
        var dictionary: [String: TopicProgress] = [:]
        for topic in remote {
            dictionary[topic.topicId] = topic
        }
        for topic in local {
            if var existing = dictionary[topic.topicId] {
                existing.totalAnswers = max(existing.totalAnswers, topic.totalAnswers)
                existing.correctAnswers = max(existing.correctAnswers, topic.correctAnswers)
                existing.streak = max(existing.streak, topic.streak)
                existing.masteryLevel = maxMastery(existing.masteryLevel, topic.masteryLevel)
                existing.recommendedDifficulty = topic.recommendedDifficulty ?? existing.recommendedDifficulty
                existing.lastActivityAt = max(existing.lastActivityAt ?? .distantPast, topic.lastActivityAt ?? .distantPast)
                dictionary[topic.topicId] = existing
            } else {
                dictionary[topic.topicId] = topic
            }
        }
        return Array(dictionary.values)
    }

    private func masteryLevel(for accuracy: Double) -> MasteryLevel {
        switch accuracy {
        case ..<50:
            return .novice
        case 50..<70:
            return .learning
        case 70..<90:
            return .proficient
        default:
            return .expert
        }
    }

    private func maxMastery(_ lhs: MasteryLevel, _ rhs: MasteryLevel) -> MasteryLevel {
        if lhs == rhs { return lhs }
        let order: [MasteryLevel] = [.novice, .learning, .proficient, .expert]
        return order.firstIndex(of: lhs)! > order.firstIndex(of: rhs)! ? lhs : rhs
    }

    private func recommendedDifficulty(for mastery: MasteryLevel) -> Difficulty? {
        switch mastery {
        case .novice:
            return .easy
        case .learning:
            return .medium
        case .proficient, .expert:
            return .hard
        }
    }

    private func formattedName(from components: PersonNameComponents?) -> String? {
        guard let components else { return nil }
        let formatter = PersonNameComponentsFormatter()
        return formatter.string(from: components)
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms = (0..<16).map { _ in UInt8.random(in: 0...255) }
            for random in randoms {
                if remainingLength == 0 {
                    break
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func mergeQuizHistory(remote: [QuizHistoryEntry], local: [QuizHistoryEntry]) -> [QuizHistoryEntry] {
        var dictionary: [UUID: QuizHistoryEntry] = [:]
        for entry in remote {
            dictionary[entry.id] = entry
        }
        for entry in local {
            dictionary[entry.id] = entry
        }
        let merged = dictionary.values.sorted { $0.date > $1.date }
        return Array(merged.prefix(20))
    }

    private func mergeExamHistory(remote: [ExamHistoryEntry], local: [ExamHistoryEntry]) -> [ExamHistoryEntry] {
        var dictionary: [UUID: ExamHistoryEntry] = [:]
        for entry in remote {
            dictionary[entry.id] = entry
        }
        for entry in local {
            dictionary[entry.id] = entry
        }
        let merged = dictionary.values.sorted { $0.date > $1.date }
        return Array(merged.prefix(20))
    }
    
    deinit {
        syncTask?.cancel()
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
        rebuildProgressFromLocalStats()
        localStore.saveProfile(profile)
        scheduleSync()
    }
    
    func statsManagerDidUpdate(_ manager: StatsManager) {
        // Обновляем progress из локальных данных при изменении статистики (например, при исправлении ошибок)
        rebuildProgressFromLocalStats()
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
        rebuildProgressFromLocalStats()
        localStore.saveProfile(profile)
        scheduleSync()
    }
    
    // MARK: - Error Handling
    private func userFriendlyErrorMessage(from error: Error) -> String {
        // Log the original error for debugging
        AppLogger.error("CloudKit sync error", error: error, category: AppLogger.data)
        
        // Get error description in lowercase for pattern matching
        let errorDescription = error.localizedDescription.lowercased()
        
        // Check for "oplock" errors first (most common conflict error)
        if errorDescription.contains("oplock") {
            AppLogger.info("Detected oplock error, returning conflict message", category: AppLogger.data)
            return NSLocalizedString("profile.sync.error.conflict", comment: "Sync conflict error")
        }
        
        // Check for CKError first
        if let ckError = error as? CKError {
            switch ckError.code {
            case .serverRecordChanged, .requestRateLimited:
                return NSLocalizedString("profile.sync.error.conflict", comment: "Sync conflict error")
            case .networkUnavailable, .networkFailure:
                return NSLocalizedString("profile.sync.error.network", comment: "Network error")
            case .quotaExceeded:
                return NSLocalizedString("profile.sync.error.quota", comment: "Quota exceeded error")
            case .notAuthenticated:
                return NSLocalizedString("profile.sync.error.auth", comment: "Authentication error")
            case .permissionFailure:
                return NSLocalizedString("profile.sync.error.permission", comment: "Permission error")
            default:
                break
            }
        }
        
        // Check for NSError with CloudKit domain
        if let nsError = error as NSError? {
            if nsError.domain == "CKErrorDomain" || nsError.domain.contains("CloudKit") {
                // This is a CloudKit error
                if errorDescription.contains("oplock") {
                    return NSLocalizedString("profile.sync.error.conflict", comment: "Sync conflict error")
                }
            }
        }
        
        // Check error description for other patterns
        if errorDescription.contains("network") || errorDescription.contains("internet") {
            return NSLocalizedString("profile.sync.error.network", comment: "Network error")
        }
        if errorDescription.contains("quota") || errorDescription.contains("limit") {
            return NSLocalizedString("profile.sync.error.quota", comment: "Quota exceeded error")
        }
        if errorDescription.contains("permission") || errorDescription.contains("unauthorized") {
            return NSLocalizedString("profile.sync.error.permission", comment: "Permission error")
        }
        if errorDescription.contains("not authenticated") || errorDescription.contains("authentication") {
            return NSLocalizedString("profile.sync.error.auth", comment: "Authentication error")
        }
        
        // Generic error message
        return NSLocalizedString("profile.sync.error.generic", comment: "Generic sync error")
    }
}

