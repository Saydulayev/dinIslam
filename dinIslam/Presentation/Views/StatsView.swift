//
//  StatsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct StatsView: View {
    @Environment(\.localizationProvider) private var localizationProvider
    @Bindable var statsManager: StatsManager
    @Environment(\.settingsManager) private var settingsManager
    @Environment(\.remoteQuestionsService) private var remoteService: RemoteQuestionsService
    @Environment(\.dismiss) private var dismiss
    @State private var mistakesViewModel: QuizViewModel?
    @State private var showingMistakesReview = false
    @State private var totalQuestionsCount: Int = 0
    @State private var showingResetAlert = false
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
                    // Stats Cards
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
                            GridItem(.flexible(), spacing: DesignTokens.Spacing.md)
                        ],
                        spacing: DesignTokens.Spacing.md
                    ) {
                        ProgressCardView(
                            icon: "questionmark.circle",
                            value: "\(statsManager.stats.totalQuestionsStudied)",
                            label: "stats.questionsStudied.title".localized,
                            iconColor: DesignTokens.Colors.iconBlue,
                            backgroundColor: DesignTokens.Colors.iconBlue.opacity(0.2)
                        )
                        
                        ProgressCardView(
                            icon: "checkmark.circle",
                            value: "\(statsManager.stats.correctAnswers)",
                            label: "stats.correctAnswers.title".localized,
                            iconColor: DesignTokens.Colors.iconGreen,
                            backgroundColor: DesignTokens.Colors.iconGreen.opacity(0.2)
                        )
                        
                        ProgressCardView(
                            icon: "xmark.circle",
                            value: "\(statsManager.stats.incorrectAnswers)",
                            label: "stats.incorrectAnswers.title".localized,
                            iconColor: DesignTokens.Colors.iconRed,
                            backgroundColor: DesignTokens.Colors.iconRed.opacity(0.2)
                        )
                        
                        ProgressCardView(
                            icon: "exclamationmark.circle",
                            value: "\(statsManager.stats.correctedMistakes)",
                            label: "stats.correctedMistakes.title".localized,
                            iconColor: DesignTokens.Colors.iconOrange,
                            backgroundColor: DesignTokens.Colors.iconOrange.opacity(0.2)
                        )
                        
                        ProgressCardView(
                            icon: "book.closed",
                            value: "\(totalQuestionsCount)",
                            label: "stats.totalQuestions.title".localized,
                            iconColor: DesignTokens.Colors.iconPurple,
                            backgroundColor: DesignTokens.Colors.iconPurple.opacity(0.2)
                        )
                        
                        ProgressCardView(
                            icon: "checkmark.circle",
                            value: "\(statsManager.stats.totalQuizzesCompleted)",
                            label: "stats.quizzesCompleted.title".localized,
                            iconColor: DesignTokens.Colors.iconBlue,
                            backgroundColor: DesignTokens.Colors.iconBlue.opacity(0.2)
                        )
                    }
                    
                    // Wrong Questions Section
                    if !statsManager.stats.wrongQuestionIds.isEmpty {
                        wrongQuestionsSection()
                    }
                    
                    // Sync Section
                    syncSection()
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
        .navigationTitle(localizationProvider.localizedString(for: "stats.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(localizationProvider.localizedString(for: "stats.reset")) {
                    showingResetAlert = true
                }
                .font(DesignTokens.Typography.secondarySemibold)
                .foregroundColor(DesignTokens.Colors.iconRed)
            }
        }
        .toolbarBackground(DesignTokens.Colors.background1, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $showingMistakesReview) {
            if let viewModel = mistakesViewModel {
                MistakesReviewNavigationView(viewModel: viewModel)
            }
        }
        .onAppear {
            loadTotalQuestionsCount()
        }
        .onDisappear {
            // Cancel all pending tasks when view disappears
            updateTask?.cancel()
            syncTask?.cancel()
            loadQuestionsTask?.cancel()
            mistakesTask?.cancel()
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
    }
    
    // MARK: - Wrong Questions Section
    private func wrongQuestionsSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("stats.wrongQuestions".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("stats.wrongQuestionsCount.title".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Spacer()
                    Text("\(statsManager.stats.wrongQuestionsCount)")
                        .font(DesignTokens.Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.iconRed)
                }
                
                MinimalButton(
                    icon: "arrow.clockwise",
                    title: "stats.repeatMistakes".localized,
                    foregroundColor: DesignTokens.Colors.iconRed
                ) {
                    startMistakesReview()
                }
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .cardStyle(
            cornerRadius: DesignTokens.CornerRadius.xlarge,
            fillColor: DesignTokens.Colors.cardBackground,
            borderColor: DesignTokens.Colors.iconRed.opacity(0.3),
            shadowColor: Color.black.opacity(0.2),
            shadowRadius: 8,
            shadowYOffset: 4
        )
    }
    
    // MARK: - Sync Section
    private func syncSection() -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("stats.sync.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("stats.sync.status".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Spacer()
                    if remoteService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(DesignTokens.Colors.textSecondary)
                    } else if remoteService.hasUpdates {
                        Text("stats.sync.available".localized)
                            .font(DesignTokens.Typography.secondaryRegular)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.iconGreen)
                    } else {
                        Text("stats.sync.upToDate".localized)
                            .font(DesignTokens.Typography.secondaryRegular)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.iconBlue)
                    }
                }
                
                if remoteService.hasUpdates {
                    HStack {
                        Text("stats.sync.newQuestions.title".localized)
                            .font(DesignTokens.Typography.label)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Spacer()
                        Text("+\(remoteService.remoteQuestionsCount - remoteService.cachedQuestionsCount)")
                            .font(DesignTokens.Typography.label)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.iconGreen)
                    }
                }
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    MinimalButton(
                        icon: "arrow.clockwise",
                        title: "stats.sync.check".localized,
                        foregroundColor: DesignTokens.Colors.iconBlue
                    ) {
                        updateTask?.cancel()
                        updateTask = Task { @MainActor in
                            await checkForUpdates()
                        }
                    }
                    .disabled(remoteService.isLoading)
                    .opacity(remoteService.isLoading ? 0.6 : 1.0)
                    
                    if remoteService.hasUpdates {
                        MinimalButton(
                            icon: "arrow.down.circle",
                            title: "stats.sync.sync".localized,
                            foregroundColor: DesignTokens.Colors.iconGreen
                        ) {
                            syncTask?.cancel()
                            syncTask = Task { @MainActor in
                                await syncQuestions()
                            }
                        }
                        .disabled(remoteService.isLoading)
                        .opacity(remoteService.isLoading ? 0.6 : 1.0)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .cardStyle(
            cornerRadius: DesignTokens.CornerRadius.xlarge,
            fillColor: DesignTokens.Colors.cardBackground,
            borderColor: DesignTokens.Colors.iconBlue.opacity(0.3),
            shadowColor: Color.black.opacity(0.2),
            shadowRadius: 8,
            shadowYOffset: 4
        )
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
                AppLogger.error("StatsView: Failed to load questions count", error: error, category: AppLogger.data)
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
    StatsView(statsManager: StatsManager())
        .environment(\.settingsManager, SettingsManager())
        .environment(\.remoteQuestionsService, RemoteQuestionsService())
}
