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
    @Environment(\.remoteQuestionsService) private var remoteService: RemoteQuestionsService
    @Bindable var statsManager: StatsManager
    
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var showResetConfirmation = false
    @State private var isResettingProfile = false
    @State private var mistakesViewModel: QuizViewModel?
    @State private var showingMistakesReview = false
    @State private var totalQuestionsCount: Int = 0
    @State private var showingResetAlert = false
    @State private var isEditingDisplayName = false
    @State private var editingDisplayName = ""
    @State private var showingMistakesError = false
    @State private var mistakesErrorMessage: String?
    
    // Task cancellation
    @State private var updateTask: Task<Void, Never>?
    @State private var syncTask: Task<Void, Never>?
    @State private var loadQuestionsTask: Task<Void, Never>?
    @State private var mistakesTask: Task<Void, Never>?
    
    init(statsManager: StatsManager) {
        self._statsManager = Bindable(statsManager)
    }
    
    var body: some View {
        @Bindable var manager = profileManager
        
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    DesignTokens.Colors.background1,
                    DesignTokens.Colors.background2
                ],
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
                        totalQuestionsCount: totalQuestionsCount
                    )
                    
                    // Wrong Questions Section
                    if !statsManager.stats.wrongQuestionIds.isEmpty {
                        ProfileWrongQuestionsSectionView(
                            statsManager: statsManager,
                            onStartMistakesReview: startMistakesReview
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
        .toolbarBackground(DesignTokens.Colors.background1, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            manager.validateAvatar()
            loadTotalQuestionsCount()
            // Инициализируем editingDisplayName текущим значением
            if !isEditingDisplayName {
                editingDisplayName = manager.profile.customDisplayName ?? manager.displayName
            }
        }
        .onDisappear {
            // Cancel all pending tasks when view disappears
            updateTask?.cancel()
            syncTask?.cancel()
            loadQuestionsTask?.cancel()
            mistakesTask?.cancel()
        }
        .alert("profile.sync.reset.title".localized, isPresented: $showResetConfirmation) {
            Button("profile.sync.reset.confirm".localized, role: .destructive) {
                Task { @MainActor [manager] in
                    isResettingProfile = true
                    await manager.resetProfileData()
                    isResettingProfile = false
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
                showingResetAlert = false
            }
        } message: {
            Text("stats.reset.confirm.message".localized)
        }
        .alert(
            "error.title".localized,
            isPresented: $showingMistakesError
        ) {
            Button("error.ok".localized) {
                showingMistakesError = false
                mistakesErrorMessage = nil
            }
        } message: {
            if let errorMessage = mistakesErrorMessage {
                Text(errorMessage)
            }
        }
        .navigationDestination(isPresented: $showingMistakesReview) {
            if let viewModel = mistakesViewModel {
                MistakesReviewNavigationView(viewModel: viewModel)
            }
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
        loadQuestionsTask = Task { @MainActor [settingsManager] in
            do {
                let questionsRepository = QuestionsRepository()
                let currentLanguage = settingsManager.settings.language.rawValue
                
                let questions = try await questionsRepository.loadQuestions(language: currentLanguage)
                
                await MainActor.run {
                    totalQuestionsCount = questions.count
                }
            } catch {
                AppLogger.error("UnifiedProfileView: Failed to load questions count", error: error, category: AppLogger.data)
                await MainActor.run {
                    totalQuestionsCount = 0
                }
            }
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
    
    private func startMistakesReview() {
        // Cancel any existing mistakes review task
        mistakesTask?.cancel()
        
        // Используем существующие экземпляры из DI контейнера
        let dependencies = DIContainer.createDependencies()
        let viewModel = QuizViewModel(
            quizUseCase: dependencies.quizUseCase, 
            statsManager: statsManager, 
            settingsManager: settingsManager
        )
        
        mistakesViewModel = viewModel
        showingMistakesReview = true
        
        // Start mistakes review task
        mistakesTask = Task { @MainActor [viewModel, settingsManager] in
            // Get current language from settings
            let currentLanguage: AppLanguage = settingsManager.settings.language == .system ? 
                (Locale.current.language.languageCode?.identifier == "en" ? .english : .russian) :
                settingsManager.settings.language
            
            await viewModel.startMistakesReview(language: currentLanguage.rawValue)
            
            // Check for errors after completion
            if let errorMessage = viewModel.errorMessage {
                showingMistakesReview = false
                mistakesErrorMessage = errorMessage
                showingMistakesError = true
            }
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
        UnifiedProfileView(statsManager: statsManager)
    }
    .environment(\.profileManager, profileManager)
    .environment(\.settingsManager, SettingsManager())
    .environment(\.remoteQuestionsService, RemoteQuestionsService())
}
