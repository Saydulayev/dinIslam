//
//  StatsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct StatsView: View {
    @State private var statsManager: StatsManager
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var remoteService: RemoteQuestionsService
    @Environment(\.dismiss) private var dismiss
    @State private var mistakesViewModel: QuizViewModel?
    @State private var showingMistakesReview = false
    @State private var totalQuestionsCount: Int = 0
    @State private var showingResetAlert = false
    
    // Task cancellation
    @State private var updateTask: Task<Void, Never>?
    @State private var syncTask: Task<Void, Never>?
    @State private var loadQuestionsTask: Task<Void, Never>?
    
    init(statsManager: StatsManager) {
        self._statsManager = State(initialValue: statsManager)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header - теперь внутри скролла
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("stats.title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Stats Cards - фиксированная сетка
                LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "stats.questionsStudied".localized,
                            value: "\(statsManager.stats.totalQuestionsStudied)",
                            icon: "questionmark.circle.fill",
                            color: .blue,
                            isCompact: false
                        )
                        
                        StatCard(
                            title: "stats.correctAnswers".localized,
                            value: "\(statsManager.stats.correctAnswers)",
                            icon: "checkmark.circle.fill",
                            color: .green,
                            isCompact: false
                        )
                        
                        StatCard(
                            title: "stats.incorrectAnswers".localized,
                            value: "\(statsManager.stats.incorrectAnswers)",
                            icon: "xmark.circle.fill",
                            color: .red,
                            isCompact: false
                        )
                        
                        StatCard(
                            title: "stats.correctedMistakes".localized,
                            value: "\(statsManager.stats.correctedMistakes)",
                            icon: "checkmark.circle.badge.xmark",
                            color: .orange,
                            isCompact: false
                        )
                        
                        StatCard(
                            title: "stats.totalQuestions".localized,
                            value: "\(totalQuestionsCount)",
                            icon: "book.fill",
                            color: .purple,
                            isCompact: false
                        )
                        
                        StatCard(
                            title: "stats.quizzesCompleted".localized,
                            value: "\(statsManager.stats.totalQuizzesCompleted)",
                            icon: "checkmark.circle.fill",
                            color: .blue,
                            isCompact: false
                        )
                    }
                    
                    // Wrong Questions Section - увеличенная
                    if !statsManager.stats.wrongQuestionIds.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("stats.wrongQuestions".localized)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("stats.wrongQuestionsCount".localized)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(statsManager.stats.wrongQuestionsCount)")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
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
                            }
                            .padding(20)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    
                    // Sync Section - в самом низу
                    VStack(alignment: .leading, spacing: 12) {
                        Text("stats.sync.title".localized)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("stats.sync.status".localized)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if remoteService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else if remoteService.hasUpdates {
                                    Text("stats.sync.available".localized)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                } else {
                                    Text("stats.sync.upToDate".localized)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if remoteService.hasUpdates {
                                HStack {
                                    Text("stats.sync.newQuestions".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("+\(remoteService.remoteQuestionsCount - remoteService.cachedQuestionsCount)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    updateTask?.cancel()
                                    updateTask = Task {
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
                                
                                if remoteService.hasUpdates {
                                    Button(action: {
                                        syncTask?.cancel()
                                        syncTask = Task {
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
            .navigationTitle(LocalizationManager.shared.localizedString(for: "stats.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString(for: "stats.reset")) {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
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
    }
    
    private func loadTotalQuestionsCount() {
        loadQuestionsTask?.cancel()
        loadQuestionsTask = Task {
            do {
                let questionsRepository = QuestionsRepository()
                let currentLanguage = settingsManager.settings.language.rawValue
                
                let questions = try await questionsRepository.loadQuestions(language: currentLanguage)
                
                await MainActor.run {
                    totalQuestionsCount = questions.count
                    print("📊 StatsView: Total=\(questions.count) questions")
                }
            } catch {
                print("❌ StatsView: Failed to load questions count: \(error)")
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
            print("🔄 StatsView: Synced \(questions.count) questions")
        }
    }
    
    private func startMistakesReview() {
        print("DEBUG: Starting mistakes review...")
        print("DEBUG: Wrong questions count: \(statsManager.stats.wrongQuestionIds.count)")
        
        // Используем существующие экземпляры из DI контейнера
        let container = DIContainer.shared
        let viewModel = QuizViewModel(
            quizUseCase: container.quizUseCase, 
            statsManager: statsManager, 
            settingsManager: settingsManager
        )
        
        mistakesViewModel = viewModel
        showingMistakesReview = true
        
        let mistakesTask = Task {
            print("DEBUG: Starting async mistakes review...")
            await viewModel.startMistakesReview()
            print("DEBUG: Mistakes review completed. State: \(viewModel.state)")
        }
        
        // Store task for potential cancellation
        updateTask = mistakesTask
    }
    
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isCompact: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct ProgressRow: View {
    let title: String
    let value: Int
    let color: Color
    let isCompact: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(isCompact ? .subheadline : .body)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value)")
                .font(isCompact ? .subheadline : .body)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    StatsView(statsManager: StatsManager())
        .environmentObject(SettingsManager())
        .environmentObject(RemoteQuestionsService())
}

