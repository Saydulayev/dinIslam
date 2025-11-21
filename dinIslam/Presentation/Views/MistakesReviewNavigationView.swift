//
//  MistakesReviewNavigationView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct MistakesReviewNavigationView: View {
    @Bindable var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizationProvider) private var localizationProvider
    
    init(viewModel: QuizViewModel) {
        _viewModel = Bindable(viewModel)
    }
    
    var body: some View {
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
            
            Group {
                switch viewModel.state {
                case .active(.loading):
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.iconBlue))
                            .scaleEffect(1.5)
                        Text("mistakes.loading".localized)
                            .font(DesignTokens.Typography.bodyRegular)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .active(.mistakesReview):
                    MistakesReviewView(viewModel: viewModel)
                    
                case .completed(.mistakesFinished):
                    // Show result screen when mistakes review is finished
                    if let result = viewModel.quizResult {
                        MistakesResultView(
                            result: result,
                            onRepeat: {
                                viewModel.restartQuiz()
                            },
                            onBackToStart: {
                                viewModel.restartQuiz()
                                dismiss()
                            }
                        )
                    } else {
                        // Fallback if result is not ready yet
                        VStack(spacing: DesignTokens.Spacing.lg) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.iconBlue))
                                .scaleEffect(1.5)
                            Text("mistakes.loading".localized)
                                .font(DesignTokens.Typography.bodyRegular)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                case .idle:
                    // User stopped the mistakes review - onChange will handle dismiss
                    // This case should rarely be visible, but kept as fallback
                    EmptyView()
                    
                default:
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Text("mistakes.error".localized)
                            .font(DesignTokens.Typography.h2)
                            .foregroundColor(DesignTokens.Colors.iconRed)
                        
                        Button("mistakes.back".localized) {
                            dismiss()
                        }
                        .font(DesignTokens.Typography.secondarySemibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                        .padding(.vertical, DesignTokens.Spacing.lg)
                        .background(
                            ZStack {
                                // Градиентный фон кнопки
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignTokens.Colors.blueGradientStart,
                                        DesignTokens.Colors.blueGradientEnd
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                
                                // Рамка с градиентом и свечением
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
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
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle(localizationProvider.localizedString(for: "mistakes.reviewTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.clear, for: .navigationBar) // прозрачный toolbar для градиента
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: viewModel.state) { _, newState in
            // Auto-dismiss when user stops the review
            if case .idle = newState {
                dismiss()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                }
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
    let viewModel = QuizViewModel(
        quizUseCase: quizUseCase,
        statsManager: statsManager,
        settingsManager: SettingsManager()
    )
    MistakesReviewNavigationView(viewModel: viewModel)
}
