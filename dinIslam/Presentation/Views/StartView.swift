//
//  StartView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI
import Observation
#if os(iOS)
import UIKit
#endif

enum StartRoute: Hashable {
    case quiz
    case result(ResultSnapshot)
    case achievements
    case settings
    case profile
    case exam
    case bankCompletion(totalQuestions: Int)
    
    struct ResultSnapshot: Hashable {
        let totalQuestions: Int
        let correctAnswers: Int
        let percentage: Double
        let timeSpent: Double
        let report: SessionReport?
        
        init(from result: QuizResult, report: SessionReport? = nil) {
            totalQuestions = result.totalQuestions
            correctAnswers = result.correctAnswers
            percentage = result.percentage
            timeSpent = result.timeSpent
            self.report = report
        }
        
        func makeQuizResult() -> QuizResult {
            QuizResult(
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                percentage: percentage,
                timeSpent: timeSpent
            )
        }
    }
}

struct StartView: View {
    @State private var model: StartViewModel
    @Environment(\.achievementManager) private var achievementManager
    
    init(model: StartViewModel) {
        _model = State(initialValue: model)
    }
    
    init(
        quizUseCase: QuizUseCaseProtocol,
        statsManager: StatsManager,
        settingsManager: SettingsManager,
        profileManager: ProfileManager,
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager,
        enhancedQuizUseCase: EnhancedQuizUseCaseProtocol,
        achievementManager: AchievementManager
    ) {
        let quizViewModel = QuizViewModel(
            quizUseCase: quizUseCase,
            statsManager: statsManager,
            settingsManager: settingsManager,
            achievementManager: achievementManager
        )
        let questionsPreloading = DefaultQuestionsPreloadingService(
            enhancedQuizUseCase: enhancedQuizUseCase
        )
        _model = State(
            initialValue: StartViewModel(
                quizViewModel: quizViewModel,
                statsManager: statsManager,
                settingsManager: settingsManager,
                profileManager: profileManager,
                examUseCase: examUseCase,
                examStatisticsManager: examStatisticsManager,
                questionsPreloading: questionsPreloading,
                enhancedQuizUseCase: enhancedQuizUseCase
            )
        )
    }
    
    var body: some View {
        navigationContent(bindingModel: $model)
            .id(model.settingsManager.settings.language)
    }

    private func navigationContent(bindingModel: Binding<StartViewModel>) -> some View {
        let model = bindingModel.wrappedValue
        return NavigationStack(path: bindingModel.navigationPath) {
            ZStack {
                // Background - очень темный градиент с оттенками индиго/фиолетового
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#0a0a1a"), // темно-индиго сверху
                        Color(hex: "#000000") // черный снизу
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                GeometryReader { proxy in
                    ScrollView {
                        VStack(spacing: DesignTokens.Spacing.xxl) {
                            heroSection(model: model)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignTokens.Spacing.xxxl)
                            summarySection(model: model)
                                .padding(.horizontal, DesignTokens.Spacing.xxl)
                        }
                        .padding(.bottom, DesignTokens.Spacing.xxxl)
                        .frame(minHeight: proxy.size.height, alignment: .bottom)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .navigationDestination(for: StartRoute.self) { route in
                @Bindable var quizViewModel = model.quizViewModel
                switch route {
                case .quiz:
                    QuizView(viewModel: quizViewModel)
                case .result(let snapshot):
                    ResultView(
                        result: snapshot.makeQuizResult(),
                        newAchievements: quizViewModel.newAchievements,
                        onPlayAgain: {
                            model.resetQuiz()
                            model.startQuiz()
                        },
                        onBackToStart: {
                            model.resetQuiz()
                        },
                        onAchievementsCleared: {
                            model.clearNewAchievements()
                        },
                        report: snapshot.report,
                        onRepeatMistakes: { mistakeIds in
                            model.startReview(scope: .questions(Set(mistakeIds)))
                        }
                    )
                case .achievements:
                    AchievementsView(achievementManager: achievementManager)
                case .settings:
                    SettingsViewWithDependencies(settingsManager: model.settingsManager)
                case .profile:
                    UnifiedProfileView(
                        statsManager: model.statsManager,
                        onStartMistakesReview: {
                            model.startReview(scope: .all)
                        }
                    )
                case .exam:
                    if let examViewModel = model.examViewModel {
                        ExamView(viewModel: examViewModel) {
                            model.finishExamSession()
                        }
                    }
                case .bankCompletion(let totalQuestions):
                    BankCompletionView(
                        totalQuestions: totalQuestions,
                        onStartOver: {
                            model.resetQuestionPool()
                            model.resetQuiz()
                        },
                        onStartReview: {
                            model.enableReviewMode()
                            model.resetQuiz()
                            model.startQuiz()
                        }
                    )
                }
            }
            .sheet(isPresented: bindingModel.showingExamSettings) {
                ExamSettingsView { configuration in
                    model.startExam(with: configuration)
                }
                .environment(\.settingsManager, model.settingsManager)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar) // прозрачный toolbar для градиента
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            model.showProfile()
                        }) {
                            Label("start.menu.profile".localized, systemImage: "person.crop.circle")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            model.showAchievements()
                        }) {
                            Label("start.menu.achievements".localized, systemImage: "trophy.fill")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            model.showSettings()
                        }) {
                            Label("start.menu.settings".localized, systemImage: "gearshape.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                    .accessibilityLabel("accessibility.menu".localized)
                }
            }
            .alert(
                "error.title".localized,
                isPresented: Binding(
                    get: { model.quizViewModel.errorMessage != nil },
                    set: { newValue in
                        if !newValue {
                            model.quizViewModel.errorMessage = nil
                        }
                    }
                )
            ) {
                Button("error.ok".localized) {
                    model.quizViewModel.errorMessage = nil
                }
            } message: {
                Text(model.quizViewModel.errorMessage ?? "")
            }
            .onAppear {
                model.onAppear()
            }
        }
        .onDisappear {
            model.onDisappear()
        }
        .onChange(of: model.settingsManager.settings.language) { _, _ in
            model.onLanguageChange()
        }
        .onChange(of: model.quizViewModel.state) { _, newValue in
            model.onQuizStateChange(newValue)
        }
    }
    
    // MARK: - View Sections
    private func heroSection(model: StartViewModel) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Используем новый оптимизированный компонент логотипа
            LogoView(glowIntensity: model.logoGlowIntensity)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                LocalizedText("app.name")
                    .font(DesignTokens.Typography.h1)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                
                LocalizedText("start.description")
                    .font(DesignTokens.Typography.bodyRegular)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }
        }
    }
    
    private func summarySection(model: StartViewModel) -> some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            statsCard(model: model)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            actionsSection(model: model)
        }
        .padding(DesignTokens.Spacing.xxl)
        .background(
            // Прозрачная рамка с фиолетовым свечением
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Colors.iconPurpleLight.opacity(0.5),
                            DesignTokens.Colors.iconPurpleLight.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(
                    color: DesignTokens.Colors.iconPurpleLight.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 0
                )
        )
    }
    
    private func statsCard(model: StartViewModel) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            streakTile(model: model)
            averageScoreTile(model: model)
        }
        // Обе плитки по высоте более высокой — при крупном шрифте рамки остаются ровными
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func streakTile(model: StartViewModel) -> some View {
        let streak = model.statsManager.dayStreak
        let isActiveToday = model.statsManager.isActiveToday
        let caption: String
        if isActiveToday {
            caption = "start.streak.activeToday".localized
        } else if streak > 0 {
            caption = "start.streak.keepGoing".localized
        } else {
            caption = "start.streak.start".localized
        }
        
        return VStack(spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(streak > 0 ? DesignTokens.Colors.iconOrange : DesignTokens.Colors.textTertiary)
                Text("\(streak)")
                    .font(DesignTokens.Typography.h1)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
            Text("streak.days".localized(count: streak))
                .font(DesignTokens.Typography.label)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            Text(caption)
                .font(DesignTokens.Typography.label)
                .foregroundStyle(isActiveToday ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 96, maxHeight: .infinity)
        .cardStyle(fillColor: Color.white.opacity(0.04), borderColor: Color.white.opacity(0.08), shadowColor: .clear)
        .accessibilityElement(children: .combine)
    }
    
    private func averageScoreTile(model: StartViewModel) -> some View {
        let hasGames = model.statsManager.hasRecentGames()
        return VStack(spacing: DesignTokens.Spacing.xs) {
            Text(hasGames ? "\(Int(model.statsManager.getAverageRecentScore()))%" : "—")
                .font(DesignTokens.Typography.h1)
                .foregroundStyle(hasGames ? DesignTokens.Colors.iconBlueLight : DesignTokens.Colors.textTertiary)
            LocalizedText(hasGames ? "start.averageScore" : "start.noGamesYet")
                .font(DesignTokens.Typography.label)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            if hasGames {
                Text("start.basedOnGames".localized(count: model.statsManager.getRecentGamesCount(), arguments: model.statsManager.getRecentGamesCount()))
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 96, maxHeight: .infinity)
        .cardStyle(fillColor: Color.white.opacity(0.04), borderColor: Color.white.opacity(0.08), shadowColor: .clear)
        .accessibilityElement(children: .combine)
    }
    
    private func actionsSection(model: StartViewModel) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            dailyButton(model: model)
            if model.statsManager.dueReviewCount > 0 {
                reviewButton(model: model)
            }
            quizButton(model: model)
            examButton(model: model)
        }
    }
    
    private func dailyButton(model: StartViewModel) -> some View {
        let isCompleted = model.statsManager.isDailyGoalCompletedToday
        return GradientActionButton(
            icon: isCompleted ? "checkmark.circle.fill" : "sun.max.fill",
            title: "start.daily.title".localized,
            subtitle: (isCompleted ? "start.daily.completed" : "start.daily.subtitle").localized(arguments: DailyProgress.dailyGoalQuestions),
            gradient: [DesignTokens.Colors.greenGradientStart, DesignTokens.Colors.greenGradientEnd],
            isLoading: model.quizViewModel.isLoading && model.quizViewModel.sessionKind == .daily
        ) {
            model.startDailyPractice()
        }
        .disabled(model.quizViewModel.isLoading)
    }
    
    private func reviewButton(model: StartViewModel) -> some View {
        GradientActionButton(
            icon: "arrow.triangle.2.circlepath",
            title: "start.review.title".localized,
            subtitle: "start.review.subtitle".localized,
            badge: "\(model.statsManager.dueReviewCount)",
            gradient: [DesignTokens.Colors.amberGradientStart, DesignTokens.Colors.amberGradientEnd],
            isLoading: model.quizViewModel.isLoading && model.quizViewModel.sessionKind == .review
        ) {
            model.startReview(scope: .due)
        }
        .disabled(model.quizViewModel.isLoading)
    }
    
    private func quizButton(model: StartViewModel) -> some View {
        GradientActionButton(
            icon: "play.fill",
            title: "start.begin".localized,
            subtitle: "start.quiz.subtitle".localized(arguments: QuizUseCase.standardSessionSize),
            gradient: [DesignTokens.Colors.quizButtonGradientStart, DesignTokens.Colors.quizButtonGradientEnd],
            isLoading: model.quizViewModel.isLoading && model.quizViewModel.sessionKind == .standard
        ) {
            model.startQuiz()
        }
        .disabled(model.quizViewModel.isLoading)
    }
    
    private func examButton(model: StartViewModel) -> some View {
        GradientActionButton(
            icon: "timer",
            title: "start.examMode".localized,
            gradient: [DesignTokens.Colors.examButtonGradientStart, DesignTokens.Colors.examButtonGradientEnd]
        ) {
            model.showingExamSettings = true
        }
    }
    
}

#Preview {
    let statsManager = StatsManager()
    let settingsManager = SettingsManager()
    let examStatsManager = ExamStatisticsManager()
    let adaptiveEngine = AdaptiveLearningEngine()
    let profileManager = ProfileManager(
        adaptiveEngine: adaptiveEngine,
        statsManager: statsManager,
        examStatisticsManager: examStatsManager
    )
    let notificationManager = NotificationManager()
    let achievementManager = AchievementManager(
        notificationManager: notificationManager,
        localizationProvider: LocalizationManager()
    )
    let adaptiveStrategy = AdaptiveQuestionSelectionStrategy(adaptiveEngine: adaptiveEngine)
    let fallbackStrategy = FallbackQuestionSelectionStrategy()
    let questionPoolProgressManager = DefaultQuestionPoolProgressManager()
    let quizUseCase = QuizUseCase(
        questionsRepository: EnhancedQuestionsRepository(),
        profileProgressProvider: profileManager, // ProfileManager implements ProfileProgressProviding
        questionSelectionStrategy: adaptiveStrategy,
        fallbackStrategy: fallbackStrategy,
        questionPoolProgressManager: questionPoolProgressManager
    )
    let examUseCase = ExamUseCase(
        questionsRepository: EnhancedQuestionsRepository(),
        examStatisticsManager: examStatsManager
    )
    
    // Create enhanced dependencies for Preview
    let baseDependencies = AppDependencies()
    let enhancedDependencies = EnhancedDIContainer.createEnhancedDependencies(baseDependencies: baseDependencies)

    StartView(
        quizUseCase: quizUseCase,
        statsManager: statsManager,
        settingsManager: settingsManager,
        profileManager: profileManager,
        examUseCase: examUseCase,
        examStatisticsManager: examStatsManager,
        enhancedQuizUseCase: enhancedDependencies.enhancedQuizUseCase,
        achievementManager: achievementManager
    )
    .environment(\.settingsManager, settingsManager)
    .environment(\.statsManager, statsManager)
    .environment(\.profileManager, profileManager)
    .environment(\.achievementManager, achievementManager)
}

