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
    
    struct ResultSnapshot: Hashable {
        let totalQuestions: Int
        let correctAnswers: Int
        let percentage: Double
        let timeSpent: Double
        
        init(from result: QuizResult) {
            totalQuestions = result.totalQuestions
            correctAnswers = result.correctAnswers
            percentage = result.percentage
            timeSpent = result.timeSpent
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
        enhancedQuizUseCase: EnhancedQuizUseCaseProtocol
    ) {
        let quizViewModel = QuizViewModel(
            quizUseCase: quizUseCase,
            statsManager: statsManager,
            settingsManager: settingsManager
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
                questionsPreloading: questionsPreloading
            )
        )
    }
    
    init(
        quizUseCase: QuizUseCaseProtocol,
        statsManager: StatsManager,
        settingsManager: SettingsManager,
        profileManager: ProfileManager,
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager,
        enhancedContainer: EnhancedDIContainer
    ) {
        let quizViewModel = QuizViewModel(
            quizUseCase: quizUseCase,
            statsManager: statsManager,
            settingsManager: settingsManager
        )
        let questionsPreloading = DefaultQuestionsPreloadingService(
            enhancedQuizUseCase: enhancedContainer.enhancedQuizUseCase
        )
        _model = State(
            initialValue: StartViewModel(
                quizViewModel: quizViewModel,
                statsManager: statsManager,
                settingsManager: settingsManager,
                profileManager: profileManager,
                examUseCase: examUseCase,
                examStatisticsManager: examStatisticsManager,
                questionsPreloading: questionsPreloading
            )
        )
    }
    
    var body: some View {
        navigationContent(bindingModel: $model)
    }

    private func navigationContent(bindingModel: Binding<StartViewModel>) -> some View {
        let model = bindingModel.wrappedValue
        return NavigationStack(path: bindingModel.navigationPath) {
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignTokens.Colors.background1,
                        DesignTokens.Colors.background2
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
                    .scrollDisabled(false)
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
                        }
                    )
                case .achievements:
                    AchievementsView()
                case .settings:
                    SettingsViewWithDependencies(settingsManager: model.settingsManager)
                case .profile:
                    UnifiedProfileView(statsManager: model.statsManager)
                case .exam:
                    if let examViewModel = model.examViewModel {
                        ExamView(viewModel: examViewModel) {
                            model.finishExamSession()
                        }
                    }
                }
            }
            .sheet(isPresented: bindingModel.showingExamSettings) {
                ExamSettingsView { configuration in
                    model.startExam(with: configuration)
                }
                .environment(\.settingsManager, model.settingsManager)
            }
            .navigationTitle("app.name".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignTokens.Colors.background1, for: .navigationBar)
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
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DesignTokens.Colors.iconBlue.opacity(0.3 * model.logoGlowIntensity),
                                DesignTokens.Colors.iconPurple.opacity(0.2 * model.logoGlowIntensity),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Image("image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(color: DesignTokens.Colors.iconBlue.opacity(0.4 * model.logoGlowIntensity), radius: 20, x: 0, y: 10)
                    .shadow(color: DesignTokens.Colors.iconPurple.opacity(0.3 * model.logoGlowIntensity), radius: 30, x: 0, y: 0)
                
                TimelineView(.animation) { timeline in
                    ParticleFieldView(particles: model.particlesSnapshot(for: timeline.date))
                }
            }
            
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
                .background(DesignTokens.Colors.borderSubtle)
            
            actionsSection(model: model)
        }
        .padding(DesignTokens.Spacing.xxl)
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }
    
    private func statsCard(model: StartViewModel) -> some View {
        Group {
            if model.statsManager.hasRecentGames() {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    LocalizedText("start.averageScore")
                        .font(DesignTokens.Typography.bodyRegular)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    
                    Text("\(Int(model.statsManager.getAverageRecentScore()))%")
                        .font(DesignTokens.Typography.h1)
                        .foregroundStyle(DesignTokens.Colors.iconBlue)
                    
                    Text("start.basedOnGames".localized(count: model.statsManager.getRecentGamesCount(), arguments: model.statsManager.getRecentGamesCount()))
                        .font(DesignTokens.Typography.label)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                .padding(DesignTokens.Spacing.lg)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    LocalizedText("start.noGamesYet")
                        .font(DesignTokens.Typography.bodyRegular)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    
                    Text("—")
                        .font(DesignTokens.Typography.h1)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                .padding(DesignTokens.Spacing.lg)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func actionsSection(model: StartViewModel) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            quizButton(model: model)
            examButton(model: model)
        }
    }
    
    private func quizButton(model: StartViewModel) -> some View {
        Button(action: {
            model.startQuiz()
        }) {
            HStack(spacing: DesignTokens.Spacing.md) {
                if model.quizViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.iconBlue))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                        .foregroundColor(DesignTokens.Colors.iconBlue)
                }
                
                LocalizedText(model.quizViewModel.isLoading ? "start.loading" : "start.begin")
                    .font(DesignTokens.Typography.secondarySemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: DesignTokens.Sizes.iconSmall))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity)
            .cardStyle(
                cornerRadius: DesignTokens.CornerRadius.medium,
                fillColor: DesignTokens.Colors.progressCard,
                borderColor: DesignTokens.Colors.borderDefault,
                shadowColor: Color.black.opacity(0.24),
                shadowRadius: 8,
                shadowYOffset: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(model.quizViewModel.isLoading)
    }
    
    private func examButton(model: StartViewModel) -> some View {
        Button {
            model.showingExamSettings = true
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "timer")
                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                    .foregroundColor(DesignTokens.Colors.iconOrange)
                
                LocalizedText("start.examMode")
                    .font(DesignTokens.Typography.secondarySemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: DesignTokens.Sizes.iconSmall))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity)
            .cardStyle(
                cornerRadius: DesignTokens.CornerRadius.medium,
                fillColor: DesignTokens.Colors.progressCard,
                borderColor: DesignTokens.Colors.iconOrange.opacity(0.35),
                shadowColor: Color.black.opacity(0.24),
                shadowRadius: 8,
                shadowYOffset: 4
            )
        }
        .buttonStyle(.plain)
    }
    
}

private struct ParticleFieldView: View {
    let particles: [StartViewModel.Particle]

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(.yellow.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .blur(radius: 1)
            }
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
    let adaptiveStrategy = AdaptiveQuestionSelectionStrategy(adaptiveEngine: adaptiveEngine)
    let fallbackStrategy = FallbackQuestionSelectionStrategy()
    let questionPoolProgressManager = DefaultQuestionPoolProgressManager()
    let quizUseCase = QuizUseCase(
        questionsRepository: QuestionsRepository(),
        profileProgressProvider: profileManager, // ProfileManager implements ProfileProgressProviding
        questionSelectionStrategy: adaptiveStrategy,
        fallbackStrategy: fallbackStrategy,
        questionPoolProgressManager: questionPoolProgressManager
    )
    let examUseCase = ExamUseCase(
        questionsRepository: QuestionsRepository(),
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
        enhancedQuizUseCase: enhancedDependencies.enhancedQuizUseCase
    )
    .environment(\.settingsManager, settingsManager)
    .environment(\.statsManager, statsManager)
    .environment(\.profileManager, profileManager)
}

