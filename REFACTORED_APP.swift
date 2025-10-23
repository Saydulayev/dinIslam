//
//  RefactoredApp.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

// MARK: - Environment Keys
private struct StatsManagerKey: EnvironmentKey {
    static let defaultValue = StatsManager()
}

extension EnvironmentValues {
    var statsManager: StatsManager {
        get { self[StatsManagerKey.self] }
        set { self[StatsManagerKey.self] = newValue }
    }
}

@main
struct RefactoredDinIslamApp: App {
    private let container = RefactoredDIContainer.shared
    
    init() {
        // Настройка улучшенной сетевой архитектуры
        configureEnhancedNetworking()
    }
    
    private func configureEnhancedNetworking() {
        // Настройка для production
        container.configureNetwork(
            timeout: AppConstants.Timing.networkTimeout,
            maxRetries: AppConstants.Quiz.maxRetries,
            retryDelay: AppConstants.Timing.retryDelay
        )
        
        // Настройка кэша
        container.configureCache(
            ttl: AppConstants.Cache.ttl,
            maxCacheSize: AppConstants.Cache.maxCacheSize,
            compressionEnabled: true
        )
    }
    
    var body: some Scene {
        WindowGroup {
            RefactoredStartView(
                quizUseCase: container.quizUseCase,
                statsManager: container.statsManager,
                settingsManager: container.settingsManager
            )
            .environmentObject(container.settingsManager as! SettingsManager)
            .environmentObject(container.achievementManager as! AchievementManager)
            .environmentObject(container.remoteQuestionsService)
            .environmentObject(container.notificationManager as! NotificationManager)
            .environment(\.statsManager, container.statsManager as! StatsManager)
        }
    }
}

// MARK: - Refactored Start View
struct RefactoredStartView: View {
    @State private var viewModel: RefactoredQuizViewModel
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.statsManager) private var statsManager: StatsManager
    @State private var showingSettings = false
    @State private var showingStats = false
    @State private var showingAchievements = false
    @AppStorage(AppConstants.UserDefaultsKeys.bestScore) private var bestScore: Double = 0
    
    // Кэшированный код языка для избежания синхронных операций
    @State private var cachedLanguageCode: String = "ru"
    
    // Task cancellation
    @State private var startQuizTask: Task<Void, Never>?
    
    init(viewModel: RefactoredQuizViewModel) {
        self.viewModel = viewModel
    }
    
    init(quizUseCase: QuizUseCaseProtocol, statsManager: StatsManagerProtocol, settingsManager: SettingsManagerProtocol) {
        let container = RefactoredDIContainer.shared
        self.viewModel = RefactoredQuizViewModel(
            quizUseCase: quizUseCase,
            statsManager: statsManager,
            hapticManager: container.hapticManager,
            soundManager: container.soundManager,
            achievementManager: container.achievementManager
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                // App Title
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
                
                Spacer()
                
                // Best Score
                if bestScore > 0 {
                    VStack(spacing: 8) {
                        LocalizedText("start.bestScore")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(bestScore))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                
                // Start Button
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
                .padding(.horizontal)
                
                Spacer()
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
                ResultView(viewModel: viewModel, bestScore: $bestScore)
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(viewModel: SettingsViewModel(settingsManager: settingsManager))
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
                    await RefactoredDIContainer.shared.enhancedQuizUseCase.preloadQuestions(
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
}
