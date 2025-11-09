//
//  ProfileManager.swift
//  dinIslam
//
//  Created by GPT-5 Codex on 09.11.25.
//

import AuthenticationServices
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
        profile.fullName ?? NSLocalizedString("profile.anonymous", comment: "Anonymous user placeholder")
    }

    var email: String? {
        profile.email
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
            errorMessage = error.localizedDescription
            syncState = .failed(error.localizedDescription)
        }
    }

    func signOut() {
        guard isSignedIn else { return }
        let signedInProfileId = profile.id
        profile = localStore.loadOrCreateAnonymousProfile()
        statsManager.resetStats()
        examStatisticsManager.resetStatistics()
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
                errorMessage = error.localizedDescription
                syncState = .failed(error.localizedDescription)
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

    // MARK: - Sync Management
    func refreshFromCloud(mergeStrategy: ProfileMergeStrategy = .newest) async {
        guard isSignedIn else { return }
        do {
            if let remoteProfile = try await cloudService.fetchProfile(for: profile.id) {
                profile = mergeProfile(local: profile, remote: remoteProfile, strategy: mergeStrategy)
                profile.metadata.lastSyncedAt = Date()
                localStore.saveProfile(profile)
            }
        } catch {
            errorMessage = error.localizedDescription
            syncState = .failed(error.localizedDescription)
        }
    }

    private func scheduleSync() {
        localStore.saveProfile(profile)
        guard isSignedIn else { return }

        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds debounce
            await self?.performSync()
        }
    }

    private func performSync() async {
        guard isSignedIn else { return }
        syncState = .syncing
        do {
            var profileToSync = profile
            profileToSync.metadata.updatedAt = Date()
            profileToSync.metadata.lastSyncedAt = Date()
            let savedProfile = try await cloudService.saveProfile(profileToSync)
            profile = savedProfile
            localStore.saveProfile(savedProfile)
            syncState = .idle
        } catch {
            errorMessage = error.localizedDescription
            syncState = .failed(error.localizedDescription)
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

        do {
            var hasRemoteProfile = false
            if let remoteProfile = try await cloudService.fetchProfile(for: userId) {
                signedInProfile = mergeProfile(local: signedInProfile, remote: remoteProfile, strategy: .newest)
                hasRemoteProfile = true
            }

            profile = signedInProfile
            
            if !hasRemoteProfile {
                statsManager.resetStats()
                examStatisticsManager.resetStatistics()
            }
            
            localStore.saveProfile(profile)
            await performSync()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            syncState = .failed(error.localizedDescription)
        }
    }

    private func rebuildProgressFromLocalStats() {
        var progress = profile.progress
        let stats = statsManager.stats
        let examStats = examStatisticsManager.statistics

        progress.totalQuestionsAnswered = stats.totalQuestionsStudied
        progress.correctAnswers = stats.correctAnswers
        progress.incorrectAnswers = stats.incorrectAnswers
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

    private func mergeProfile(local: UserProfile, remote: UserProfile, strategy: ProfileMergeStrategy) -> UserProfile {
        var merged = remote

        switch strategy {
        case .preferLocal:
            merged.fullName = local.fullName ?? remote.fullName
            merged.email = local.email ?? remote.email
            merged.preferences = mergePreferences(remote: remote.preferences, local: local.preferences, preferLocal: true)
            merged.progress = mergeProgress(remote: remote.progress, local: local.progress, preferLocal: true)
            merged.avatarURL = local.avatarURL ?? merged.avatarURL
        case .preferRemote:
            merged.preferences = mergePreferences(remote: remote.preferences, local: local.preferences, preferLocal: false)
            merged.progress = mergeProgress(remote: remote.progress, local: local.progress, preferLocal: false)
            merged.avatarURL = remote.avatarURL ?? local.avatarURL
        case .newest:
            let preferLocal = (local.metadata.updatedAt > remote.metadata.updatedAt)
            merged.fullName = preferLocal ? (local.fullName ?? remote.fullName) : remote.fullName
            merged.email = preferLocal ? (local.email ?? remote.email) : remote.email
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
            merged.examsTaken = max(remote.examsTaken, local.examsTaken)
            merged.examsPassed = max(remote.examsPassed, local.examsPassed)
            merged.currentStreak = max(remote.currentStreak, local.currentStreak)
            merged.longestStreak = max(remote.longestStreak, local.longestStreak)
            merged.averageQuizScore = max(remote.averageQuizScore, local.averageQuizScore)
        } else {
            merged.totalQuestionsAnswered = max(remote.totalQuestionsAnswered, local.totalQuestionsAnswered)
            merged.correctAnswers = max(remote.correctAnswers, local.correctAnswers)
            merged.incorrectAnswers = max(remote.incorrectAnswers, local.incorrectAnswers)
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
}
