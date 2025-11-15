//
//  UnifiedProfileView.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import AuthenticationServices
import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct UnifiedProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.profileManager) private var profileManager
    @Environment(\.settingsManager) private var settingsManager
    @EnvironmentObject private var remoteService: RemoteQuestionsService
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
                    profileCard(manager: manager)
                    
                    // Stats Section
                    statsSection(manager: manager)
                    
                    // Wrong Questions Section
                    if !statsManager.stats.wrongQuestionIds.isEmpty {
                        wrongQuestionsSection()
                    }
                    
                    // Unified Sync Section
                    if manager.isSignedIn {
                        unifiedSyncSection(manager: manager)
                    } else {
                        questionsSyncSection()
                    }
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
    
    // MARK: - Profile Card
    private func profileCard(manager: ProfileManager) -> some View {
        let hasAvatar = avatarExists(for: manager)
        
        return VStack(spacing: DesignTokens.Spacing.xxl) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let image = avatarImage(for: manager) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: DesignTokens.Sizes.avatarSize,
                            height: DesignTokens.Sizes.avatarSize
                        )
                        .clipShape(Circle())
                        .shadow(
                            color: Color.black.opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                } else {
                    Circle()
                        .fill(DesignTokens.Colors.progressCard)
                        .frame(
                            width: DesignTokens.Sizes.avatarSize,
                            height: DesignTokens.Sizes.avatarSize
                        )
                        .overlay(
                            Image(systemName: manager.isSignedIn ? "person.crop.circle.fill" : "person.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        )
                        .shadow(
                            color: Color.black.opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                }
                
                // Edit button
                if manager.isSignedIn {
                    PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.cardBackground)
                                .frame(
                                    width: DesignTokens.Sizes.editButtonSize,
                                    height: DesignTokens.Sizes.editButtonSize
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            DesignTokens.Colors.borderSubtle,
                                            lineWidth: 1
                                        )
                                )
                                .shadow(
                                    color: Color.black.opacity(0.3),
                                    radius: 6,
                                    x: 0,
                                    y: 2
                                )
                            
                            Image(systemName: "pencil")
                                .font(.system(size: DesignTokens.Sizes.editIconSize))
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                        }
                    }
                }
            }
            
            // User name with edit functionality
            HStack(spacing: DesignTokens.Spacing.sm) {
                if isEditingDisplayName {
                    TextField("profile.displayName.placeholder".localized, text: $editingDisplayName)
                        .font(DesignTokens.Typography.h1)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .onSubmit {
                            saveDisplayName(manager: manager)
                        }
                } else {
                    Text(manager.displayName)
                        .font(DesignTokens.Typography.h1)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }
                
                if manager.isSignedIn {
                    Button(action: {
                        if isEditingDisplayName {
                            saveDisplayName(manager: manager)
                        } else {
                            editingDisplayName = manager.profile.customDisplayName ?? manager.displayName
                            isEditingDisplayName = true
                        }
                    }) {
                        Image(systemName: isEditingDisplayName ? "checkmark" : "pencil")
                            .font(.system(size: DesignTokens.Sizes.iconSmall))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
            
            // Action buttons
            VStack(spacing: DesignTokens.Spacing.sm) {
                if manager.isSignedIn {
                    if hasAvatar {
                        MinimalButton(
                            icon: "trash",
                            title: "profile.avatar.delete".localized,
                            foregroundColor: DesignTokens.Colors.textSecondary
                        ) {
                            Task { @MainActor [manager] in
                                await manager.deleteAvatar()
                            }
                        }
                    }
                    
                    MinimalButton(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "profile.signout".localized,
                        foregroundColor: DesignTokens.Colors.iconRed
                    ) {
                        manager.signOut()
                    }
                } else {
                    // Sign in with Apple button
                    SignInWithAppleButton(.signIn) { request in
                        manager.prepareSignInRequest(request)
                    } onCompletion: { result in
                        manager.handleSignInResult(result)
                    }
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                }
            }
        }
        .padding(DesignTokens.Spacing.xxxl)
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }
    
    // MARK: - Stats Section
    private func statsSection(manager: ProfileManager) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
            Text("profile.progress.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
                    count: 2
                ),
                spacing: DesignTokens.Spacing.md
            ) {
                // Questions Studied
                ProgressCardView(
                    icon: "questionmark.circle",
                    value: "\(manager.isSignedIn ? manager.progress.totalQuestionsAnswered : statsManager.stats.totalQuestionsStudied)",
                    label: manager.isSignedIn ? "profile.progress.questions".localized : "stats.questionsStudied.title".localized,
                    iconColor: DesignTokens.Colors.iconBlue,
                    backgroundColor: DesignTokens.Colors.iconBlue.opacity(0.2)
                )
                
                // Correct Answers
                ProgressCardView(
                    icon: "checkmark.circle",
                    value: "\(manager.isSignedIn ? manager.progress.correctAnswers : statsManager.stats.correctAnswers)",
                    label: manager.isSignedIn ? "profile.progress.correct".localized : "stats.correctAnswers.title".localized,
                    iconColor: DesignTokens.Colors.iconGreen,
                    backgroundColor: DesignTokens.Colors.iconGreen.opacity(0.2)
                )
                
                // Incorrect Answers
                ProgressCardView(
                    icon: "xmark.circle",
                    value: "\(manager.isSignedIn ? manager.progress.incorrectAnswers : statsManager.stats.incorrectAnswers)",
                    label: manager.isSignedIn ? "profile.progress.incorrect".localized : "stats.incorrectAnswers.title".localized,
                    iconColor: DesignTokens.Colors.iconRed,
                    backgroundColor: DesignTokens.Colors.iconRed.opacity(0.2)
                )
                
                // Corrected Mistakes
                ProgressCardView(
                    icon: "exclamationmark.circle",
                    value: "\(manager.isSignedIn ? manager.progress.correctedMistakes : statsManager.stats.correctedMistakes)",
                    label: manager.isSignedIn ? "profile.progress.corrected".localized : "stats.correctedMistakes.title".localized,
                    iconColor: DesignTokens.Colors.iconOrange,
                    backgroundColor: DesignTokens.Colors.iconOrange.opacity(0.2)
                )
                
                // Total Questions (only for non-signed in users, or show accuracy for signed in)
                if manager.isSignedIn {
                    ProgressCardView(
                        icon: "chart.bar",
                        value: "\(Int(manager.progress.averageQuizScore))%",
                        label: "profile.progress.accuracy".localized,
                        iconColor: DesignTokens.Colors.iconPurple,
                        backgroundColor: DesignTokens.Colors.iconPurple.opacity(0.2)
                    )
                } else {
                    ProgressCardView(
                        icon: "book.closed",
                        value: "\(totalQuestionsCount)",
                        label: "stats.totalQuestions.title".localized,
                        iconColor: DesignTokens.Colors.iconPurple,
                        backgroundColor: DesignTokens.Colors.iconPurple.opacity(0.2)
                    )
                }
                
                // Streak or Quizzes Completed
                if manager.isSignedIn {
                    ProgressCardView(
                        icon: "flame",
                        value: "\(manager.progress.currentStreak)",
                        label: "profile.progress.streak".localized,
                        iconColor: DesignTokens.Colors.iconOrange,
                        backgroundColor: DesignTokens.Colors.iconOrange.opacity(0.2)
                    )
                } else {
                    ProgressCardView(
                        icon: "checkmark.circle",
                        value: "\(statsManager.stats.totalQuizzesCompleted)",
                        label: "stats.quizzesCompleted.title".localized,
                        iconColor: DesignTokens.Colors.iconBlue,
                        backgroundColor: DesignTokens.Colors.iconBlue.opacity(0.2)
                    )
                }
            }
            
            // Horizontal "Total Questions" card
            HStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "book.closed")
                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                    .foregroundColor(DesignTokens.Colors.iconPurple)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("stats.totalQuestions.title".localized)
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("\(totalQuestionsCount)")
                        .font(DesignTokens.Typography.statsValue)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                Spacer()
            }
            .padding(DesignTokens.Spacing.lg)
            .cardStyle(
                cornerRadius: DesignTokens.CornerRadius.medium,
                fillColor: DesignTokens.Colors.iconPurple.opacity(0.2),
                borderColor: DesignTokens.Colors.iconPurple.opacity(0.55),
                shadowColor: Color.black.opacity(0.22)
            )
        }
        .padding(DesignTokens.Spacing.xxl)
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.xlarge)
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
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }
    
    // MARK: - Unified Sync Section
    private func unifiedSyncSection(manager: ProfileManager) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
            Text("profile.sync.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            // CloudKit Statistics Sync Section
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: syncIcon(for: manager.syncState))
                        .font(.system(size: DesignTokens.Sizes.iconSmall))
                        .foregroundColor(syncColor(for: manager.syncState))
                    
                    Text(syncMessage(for: manager))
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                
                MinimalButton(
                    icon: "icloud.fill",
                    title: "profile.sync.refresh".localized,
                    foregroundColor: DesignTokens.Colors.iconBlue
                ) {
                    Task { @MainActor [manager] in
                        await manager.refreshFromCloud(mergeStrategy: .newest)
                    }
                }
                .disabled(isResettingProfile || manager.isLoading)
                .opacity((isResettingProfile || manager.isLoading) ? 0.6 : 1.0)
            }
            
            // Divider
            Divider()
                .background(DesignTokens.Colors.borderSubtle)
            
            // Questions Sync Section
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("stats.sync.questions.status".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Spacer()
                    if remoteService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(DesignTokens.Colors.textSecondary)
                    } else if remoteService.hasUpdates {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Text("stats.sync.available".localized)
                                .font(DesignTokens.Typography.secondaryRegular)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignTokens.Colors.iconGreen)
                            if remoteService.remoteQuestionsCount > remoteService.cachedQuestionsCount {
                                Text("+\(remoteService.remoteQuestionsCount - remoteService.cachedQuestionsCount)")
                                    .font(DesignTokens.Typography.label)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignTokens.Colors.iconGreen)
                            }
                        }
                    } else {
                        Text("stats.sync.upToDate".localized)
                            .font(DesignTokens.Typography.secondaryRegular)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.iconBlue)
                    }
                }
                
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
                } else {
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
                }
            }
            
            if isResettingProfile {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(DesignTokens.Colors.textSecondary)
                    Text("profile.sync.reset.inProgress".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }
    
    // MARK: - Questions Sync Section (for non-signed in users)
    private func questionsSyncSection() -> some View {
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
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.xlarge)
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
        let container = DIContainer.shared
        let viewModel = QuizViewModel(
            quizUseCase: container.quizUseCase, 
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
    
    private func saveDisplayName(manager: ProfileManager) {
        let trimmedName = editingDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { @MainActor [manager] in
            await manager.updateDisplayName(trimmedName.isEmpty ? nil : trimmedName)
            isEditingDisplayName = false
        }
    }
    
    private func syncIcon(for state: ProfileManager.SyncState) -> String {
        switch state {
        case .idle:
            return "checkmark.circle.fill"
        case .syncing:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private func syncColor(for state: ProfileManager.SyncState) -> Color {
        switch state {
        case .idle:
            return DesignTokens.Colors.statusGreen
        case .syncing:
            return DesignTokens.Colors.iconBlue
        case .failed:
            return DesignTokens.Colors.iconOrange
        }
    }

    private func syncMessage(for manager: ProfileManager) -> String {
        switch manager.syncState {
        case .idle:
            if let date = manager.profile.metadata.lastSyncedAt {
                let formatter = RelativeDateTimeFormatter()
                // Устанавливаем локаль в зависимости от текущего языка приложения
                let currentLanguage = settingsManager.settings.language == .system ? 
                    (Locale.current.language.languageCode?.identifier ?? "ru") :
                    settingsManager.settings.language.rawValue
                formatter.locale = Locale(identifier: currentLanguage == "en" ? "en_US" : "ru_RU")
                
                let relativeTime = formatter.localizedString(for: date, relativeTo: Date())
                let formatString = "profile.sync.lastSync".localized
                return String(format: formatString, relativeTime)
            }
            return "profile.sync.never".localized
        case .syncing:
            return "profile.sync.inProgress".localized
        case .failed(let message):
            // Message is already user-friendly, no need to format
            return message
        }
    }

    private func avatarExists(for manager: ProfileManager) -> Bool {
        guard let url = manager.profile.avatarURL else { return false }
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: url.path)
    }

    #if os(iOS)
    private func avatarImage(for manager: ProfileManager) -> Image? {
        guard let url = manager.profile.avatarURL,
              FileManager.default.fileExists(atPath: url.path),
              let uiImage = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
    #else
    private func avatarImage(for manager: ProfileManager) -> Image? {
        guard let url = manager.profile.avatarURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let nsImage = NSImage(data: data) else {
            return nil
        }
        return Image(nsImage: nsImage)
    }
    #endif
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
    .environmentObject(RemoteQuestionsService())
}

