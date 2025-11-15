//
//  EnhancedStatsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct EnhancedStatsView: View {
    @Bindable var statsManager: StatsManager
    @Environment(\.settingsManager) private var settingsManager
    @EnvironmentObject private var remoteService: RemoteQuestionsService
    @Environment(\.dismiss) private var dismiss
    @State private var mistakesViewModel: QuizViewModel?
    @State private var showingMistakesReview = false
    @State private var totalQuestionsCount: Int = 0
    @State private var showingResetAlert = false
    @State private var showingMistakesError = false
    @State private var mistakesErrorMessage: String?
    
    // Accessibility and UX enhancements
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.layoutDirection) private var layoutDirection
    
    // Task cancellation
    @State private var updateTask: Task<Void, Never>?
    @State private var syncTask: Task<Void, Never>?
    @State private var loadQuestionsTask: Task<Void, Never>?
    @State private var mistakesTask: Task<Void, Never>?
    
    init(statsManager: StatsManager) {
        self._statsManager = Bindable(statsManager)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue.gradient)
                        .accessibilityHidden(true)
                    
                    Text("stats.title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .dynamicTypeSize(.accessibility1)
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Stats Cards with pluralization
                LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        EnhancedStatCard(
                            title: "stats.questionsStudied.title".localized,
                            value: statsManager.stats.totalQuestionsStudied,
                            pluralizationKey: "stats.questionsStudied",
                            icon: "questionmark.circle.fill",
                            color: .blue,
                            isCompact: false
                        )
                        
                        EnhancedStatCard(
                            title: "stats.correctAnswers.title".localized,
                            value: statsManager.stats.correctAnswers,
                            pluralizationKey: "stats.correctAnswers",
                            icon: "checkmark.circle.fill",
                            color: .green,
                            isCompact: false
                        )
                        
                        EnhancedStatCard(
                            title: "stats.incorrectAnswers.title".localized,
                            value: statsManager.stats.incorrectAnswers,
                            pluralizationKey: "stats.incorrectAnswers",
                            icon: "xmark.circle.fill",
                            color: .red,
                            isCompact: false
                        )
                        
                        EnhancedStatCard(
                            title: "stats.correctedMistakes.title".localized,
                            value: statsManager.stats.correctedMistakes,
                            pluralizationKey: "stats.correctedMistakes",
                            icon: "checkmark.circle.badge.xmark",
                            color: .orange,
                            isCompact: false
                        )
                        
                        EnhancedStatCard(
                            title: "stats.totalQuestions.title".localized,
                            value: totalQuestionsCount,
                            pluralizationKey: "stats.totalQuestions",
                            icon: "book.fill",
                            color: .purple,
                            isCompact: false
                        )
                        
                        EnhancedStatCard(
                            title: "stats.quizzesCompleted.title".localized,
                            value: statsManager.stats.totalQuizzesCompleted,
                            pluralizationKey: "stats.quizzesCompleted",
                            icon: "checkmark.circle.fill",
                            color: .blue,
                            isCompact: false
                        )
                    }
                    
                    // Wrong Questions Section
                    if !statsManager.stats.wrongQuestionIds.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("stats.wrongQuestions".localized)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .dynamicTypeSize(.accessibility1)
                                .accessibilityAddTraits(.isHeader)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("stats.wrongQuestionsCount.title".localized)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .dynamicTypeSize(.accessibility1)
                                    Spacer()
                                    Text("\(statsManager.stats.wrongQuestionsCount)")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                        .dynamicTypeSize(.accessibility1)
                                        .accessibilityLabel("stats.wrongQuestionsCount".localized(count: statsManager.stats.wrongQuestionsCount))
                                }
                                
                                Button(action: {
                                    startMistakesReview()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.body)
                                        Text("stats.repeatMistakes".localized)
                                            .font(.body)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(.red.gradient, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .accessibilityLabel("Repeat mistakes")
                                .accessibilityHint("Double tap to review incorrect answers")
                                .dynamicTypeSize(.accessibility1)
                            }
                            .padding(20)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    
                    // Sync Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("stats.sync.title".localized)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .dynamicTypeSize(.accessibility1)
                            .accessibilityAddTraits(.isHeader)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("stats.sync.status".localized)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .dynamicTypeSize(.accessibility1)
                                Spacer()
                                if remoteService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .accessibilityLabel("Loading")
                                } else if remoteService.hasUpdates {
                                    Text("stats.sync.available".localized)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                        .dynamicTypeSize(.accessibility1)
                                } else {
                                    Text("stats.sync.upToDate".localized)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                        .dynamicTypeSize(.accessibility1)
                                }
                            }
                            
                            if remoteService.hasUpdates {
                                HStack {
                                    Text("stats.sync.newQuestions.title".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .dynamicTypeSize(.accessibility1)
                                    Spacer()
                                    Text("+\(remoteService.remoteQuestionsCount - remoteService.cachedQuestionsCount)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                        .dynamicTypeSize(.accessibility1)
                                        .accessibilityLabel("stats.sync.newQuestions".localized(count: remoteService.remoteQuestionsCount - remoteService.cachedQuestionsCount))
                                }
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    updateTask?.cancel()
                                    updateTask = Task { @MainActor in
                                        await checkForUpdates()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.body)
                                        Text("stats.sync.check".localized)
                                            .font(.body)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(remoteService.isLoading)
                                .accessibilityLabel("Check for updates")
                                .accessibilityHint("Double tap to check for new questions")
                                .dynamicTypeSize(.accessibility1)
                                
                                if remoteService.hasUpdates {
                                    Button(action: {
                                        syncTask?.cancel()
                                        syncTask = Task { @MainActor in
                                            await syncQuestions()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.down.circle")
                                                .font(.body)
                                            Text("stats.sync.sync".localized)
                                                .font(.body)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(.green.gradient, in: RoundedRectangle(cornerRadius: 12))
                                    }
                                    .disabled(remoteService.isLoading)
                                    .accessibilityLabel("Sync questions")
                                    .accessibilityHint("Double tap to download new questions")
                                    .dynamicTypeSize(.accessibility1)
                                }
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
            .navigationTitle("stats.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("stats.reset".localized) {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                    .accessibilityLabel("Reset statistics")
                    .accessibilityHint("Double tap to reset all statistics")
                    .dynamicTypeSize(.accessibility1)
                }
            }
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
}

struct EnhancedStatCard: View {
    let title: String
    let value: Int
    let pluralizationKey: String
    let icon: String
    let color: Color
    let isCompact: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .accessibilityHidden(true)
            
            Text("\(value)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .dynamicTypeSize(.accessibility1)
                .accessibilityLabel("\(value)")
            
            if !pluralizationKey.isEmpty {
                Text(pluralizationKey.localized(count: value))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .dynamicTypeSize(.accessibility1)
                    .accessibilityLabel(pluralizationKey.localized(count: value))
            } else {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .dynamicTypeSize(.accessibility1)
                    .accessibilityLabel(title)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    EnhancedStatsView(statsManager: StatsManager())
        .environment(\.settingsManager, SettingsManager())
        .environmentObject(RemoteQuestionsService())
}
