//
//  UnifiedProfileView.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import PhotosUI
import SwiftUI

struct UnifiedProfileView: View {
    @Environment(\.profileManager) private var profileManager
    @Environment(\.settingsManager) private var settingsManager
    @Environment(\.remoteQuestionsService) private var remoteService: EnhancedRemoteQuestionsService
    @Bindable var statsManager: StatsManager
    /// Повторение ошибок идёт в общем потоке викторины (StartViewModel.startReview)
    let onStartMistakesReview: () -> Void
    
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var showResetConfirmation = false
    @State private var isResettingProfile = false
    @State private var totalQuestionsCount: Int = 0
    @State private var showingResetAlert = false
    @State private var statsRefreshTrigger: Int = 0
    @State private var isEditingDisplayName = false
    @State private var editingDisplayName = ""
    
    // Task cancellation
    @State private var updateTask: Task<Void, Never>?
    @State private var syncTask: Task<Void, Never>?
    @State private var loadQuestionsTask: Task<Void, Never>?
    
    init(statsManager: StatsManager, onStartMistakesReview: @escaping () -> Void) {
        self._statsManager = Bindable(statsManager)
        self.onStartMistakesReview = onStartMistakesReview
    }
    
    var body: some View {
        @Bindable var manager = profileManager
        
        ZStack {
            // Background - очень темный градиент с оттенками индиго/фиолетового (как на главном экране)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#0a0a1a"), // темно-индиго сверху
                    Color(hex: "#000000") // черный снизу
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxxl) {
                    // Profile Card
                    ProfileCardView(
                        manager: manager,
                        avatarPickerItem: $avatarPickerItem,
                        isEditingDisplayName: $isEditingDisplayName,
                        editingDisplayName: $editingDisplayName,
                        hasAvatar: ProfileViewHelpers.avatarExists(for: manager)
                    )
                    
                    // Stats Section
                    ProfileStatsSectionView(
                        manager: manager,
                        statsManager: statsManager,
                        totalQuestionsCount: totalQuestionsCount,
                        isResettingProfile: isResettingProfile,
                        statsRefreshTrigger: statsRefreshTrigger
                    )
                    
                    // Knowledge by topic
                    ProfileKnowledgeSectionView(statsManager: statsManager)
                    
                    // Wrong Questions Section
                    if !statsManager.stats.wrongQuestionIds.isEmpty {
                        ProfileWrongQuestionsSectionView(
                            statsManager: statsManager,
                            onStartMistakesReview: onStartMistakesReview
                        )
                    }
                    
                    // Sync Section
                    ProfileSyncSectionView(
                        manager: manager,
                        isResettingProfile: isResettingProfile,
                        onSyncQuestions: syncQuestions,
                        onCheckForUpdates: checkForUpdates
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
        .navigationTitle("profile.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if manager.isSignedIn {
                    Button("stats.reset".localized) {
                        showResetConfirmation = true
                    }
                    .font(DesignTokens.Typography.secondarySemibold)
                    .foregroundColor(DesignTokens.Colors.iconRed)
                    .disabled(isResettingProfile || manager.isLoading)
                } else {
                    Button("stats.reset".localized) {
                        showingResetAlert = true
                    }
                    .font(DesignTokens.Typography.secondarySemibold)
                    .foregroundColor(DesignTokens.Colors.iconRed)
                }
            }
        }
        .toolbarBackground(.clear, for: .navigationBar) // прозрачный toolbar для градиента
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            manager.validateAvatar()
            loadTotalQuestionsCount()
            // Инициализируем editingDisplayName текущим значением
            if !isEditingDisplayName {
                let name = manager.profile.customDisplayName ?? manager.displayName
                editingDisplayName = String(name.prefix(DesignTokens.Limits.maxDisplayNameLength))
            }
        }
        .onDisappear {
            // Cancel all pending tasks when view disappears
            updateTask?.cancel()
            syncTask?.cancel()
            loadQuestionsTask?.cancel()
        }
        .alert("profile.sync.reset.title".localized, isPresented: $showResetConfirmation) {
            Button("profile.sync.reset.confirm".localized, role: .destructive) {
                Task { @MainActor [manager] in
                    isResettingProfile = true
                    await manager.resetProfileData()
                    isResettingProfile = false
                    // Триггерим обновление статистики после сброса
                    statsRefreshTrigger += 1
                }
            }
            Button("profile.sync.reset.cancel".localized, role: .cancel) { }
        } message: {
            Text("profile.sync.reset.message".localized)
        }
        .alert(
            "stats.reset.confirm.title".localized,
            isPresented: $showingResetAlert
        ) {
            Button("stats.reset.confirm.cancel".localized, role: .cancel) {
                showingResetAlert = false
            }
            Button("stats.reset.confirm.ok".localized, role: .destructive) {
                statsManager.resetStatsExceptTotalQuestions()
                // Очищаем прогресс изучения вопросов (usedIds)
                let questionPoolProgressManager = DefaultQuestionPoolProgressManager()
                questionPoolProgressManager.reset(version: 1)
                questionPoolProgressManager.setReviewMode(false, version: 1)
                showingResetAlert = false
                // Триггерим обновление статистики
                statsRefreshTrigger += 1
            }
        } message: {
            Text("stats.reset.confirm.message".localized)
        }
        .onChange(of: avatarPickerItem) { previous, current in
            guard let item = current, previous != current else { return }
            Task { @MainActor [manager] in
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let fileExtension = item.supportedContentTypes.first?.preferredFilenameExtension ?? "dat"
                    await manager.updateAvatar(with: data, fileExtension: fileExtension)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadTotalQuestionsCount() {
        loadQuestionsTask?.cancel()
        loadQuestionsTask = Task { @MainActor [settingsManager, remoteService] in
            // Same service as the quiz: fresh cache is used without a network request
            let language: AppLanguage = settingsManager.settings.language == .english ? .english : .russian
            let questions = await remoteService.fetchQuestions(for: language, manageLoadingState: false)
            totalQuestionsCount = questions.count
        }
    }
    
    private func checkForUpdates() async {
        let currentLanguage: AppLanguage = settingsManager.settings.language == .system ? 
            (Locale.current.language.languageCode?.identifier == "en" ? .english : .russian) :
            settingsManager.settings.language
        
        await remoteService.checkForUpdates(for: currentLanguage)
    }
    
    private func syncQuestions() async {
        let currentLanguage: AppLanguage = settingsManager.settings.language == .system ? 
            (Locale.current.language.languageCode?.identifier == "en" ? .english : .russian) :
            settingsManager.settings.language
        
        let questions = await remoteService.forceSync(for: currentLanguage)
        
        await MainActor.run {
            totalQuestionsCount = questions.count
        }
    }
}

#Preview {
    let statsManager = StatsManager()
    let examStatsManager = ExamStatisticsManager()
    let adaptiveEngine = AdaptiveLearningEngine()
    let profileManager = ProfileManager(
        adaptiveEngine: adaptiveEngine,
        statsManager: statsManager,
        examStatisticsManager: examStatsManager
    )
    return NavigationStack {
        UnifiedProfileView(statsManager: statsManager, onStartMistakesReview: {})
    }
    .environment(\.profileManager, profileManager)
    .environment(\.settingsManager, SettingsManager())
    .environment(\.remoteQuestionsService, EnhancedRemoteQuestionsService())
}
