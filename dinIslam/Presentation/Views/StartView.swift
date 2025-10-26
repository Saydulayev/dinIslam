//
//  StartView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI
import UserNotifications

struct StartView: View {
    @State private var viewModel: QuizViewModel
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.statsManager) private var statsManager: StatsManager
    @State private var showingSettings = false
    @State private var showingStats = false
    @State private var showingAchievements = false
    @State private var showingExamSettings = false
    @State private var showingExam = false
    @State private var examViewModel: ExamViewModel?
    
    // Кэшированный код языка для избежания синхронных операций
    @State private var cachedLanguageCode: String = "ru"
    
    // Task cancellation
    @State private var startQuizTask: Task<Void, Never>?
    
    init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
    }
    
    init(quizUseCase: QuizUseCaseProtocol, statsManager: StatsManager, settingsManager: SettingsManager) {
        self.viewModel = QuizViewModel(quizUseCase: quizUseCase, statsManager: statsManager, settingsManager: settingsManager)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // App Title - по центру экрана
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                    
                    LocalizedText("app.name")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    LocalizedText("start.description")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom section with average score and buttons
                VStack(spacing: 24) {
                    // Average Score
                    if statsManager.hasRecentGames() {
                        VStack(spacing: 8) {
                            LocalizedText("start.averageScore")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("\(Int(statsManager.getAverageRecentScore()))%")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            
                            Text(String(format: NSLocalizedString("start.basedOnGames", comment: ""), statsManager.getRecentGamesCount()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        VStack(spacing: 8) {
                            LocalizedText("start.noGamesYet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Text("—")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Regular Quiz Button
                        Button(action: {
                            startQuizTask?.cancel()
                            startQuizTask = Task {
                                await viewModel.startQuiz(language: cachedLanguageCode)
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                
                                LocalizedText(viewModel.isLoading ? "start.loading" : "start.begin")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(viewModel.isLoading)
                        
                        // Exam Mode Button
                        Button(action: {
                            showingExamSettings = true
                        }) {
                            HStack {
                                Image(systemName: "timer")
                                LocalizedText("start.examMode")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .padding()
            .navigationDestination(isPresented: .constant({
                if case .active(.playing) = viewModel.state { return true }
                return false
            }())) {
                QuizView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: .constant({
                if case .completed(.finished) = viewModel.state { return true }
                return false
            }())) {
                ResultView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(viewModel: SettingsViewModel(settingsManager: settingsManager))
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingExamSettings) {
                ExamSettingsView { configuration in
                    startExam(with: configuration)
                }
                .environmentObject(settingsManager)
            }
            .navigationDestination(isPresented: $showingExam) {
                if let examViewModel = examViewModel {
                    ExamView(viewModel: examViewModel)
                }
            }
            .navigationDestination(isPresented: $showingStats) {
                StatsView(statsManager: statsManager)
            }
            .navigationDestination(isPresented: $showingAchievements) {
                AchievementsView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showingStats = true
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showingAchievements = true
                    }) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .alert("error.title".localized,
                   isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("error.ok".localized) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                // Clear app badge when app is opened
                if #available(iOS 17.0, *) {
                    UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: { _ in })
                } else {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
                
                // Кэширование кода языка асинхронно
                Task {
                    cachedLanguageCode = settingsManager.settings.language.locale?.language.languageCode?.identifier ?? "ru"
                }
                
                // Предзагрузка вопросов для улучшения UX
                Task {
                    await EnhancedDIContainer.shared.enhancedQuizUseCase.preloadQuestions(
                        for: ["ru", "en"]
                    )
                }
            }
        }
        .onDisappear {
            // Cancel pending tasks when view disappears
            startQuizTask?.cancel()
        }
    }
    
    private func startExam(with configuration: ExamConfiguration) {
        let container = DIContainer.shared
        let examViewModel = ExamViewModel(
            examUseCase: container.examUseCase,
            examStatisticsManager: container.examStatisticsManager,
            settingsManager: settingsManager
        )
        
        self.examViewModel = examViewModel
        showingExam = true
        
        Task {
            await examViewModel.startExam(configuration: configuration, language: cachedLanguageCode)
        }
    }
}

#Preview {
    StartView(
        quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository()),
        statsManager: StatsManager(),
        settingsManager: SettingsManager()
    )
    .environmentObject(SettingsManager())
}
