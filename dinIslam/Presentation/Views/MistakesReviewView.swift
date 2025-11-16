//
//  MistakesReviewView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct MistakesReviewView: View {
    @Environment(\.localizationProvider) private var localizationProvider
    @Bindable var viewModel: QuizViewModel
    @State private var showingStopConfirm: Bool = false
    
    init(viewModel: QuizViewModel) {
        _viewModel = Bindable(viewModel)
    }
    
    // MARK: - Computed Properties
    private var progressText: String {
        "\(viewModel.currentQuestionIndex + 1) / \(viewModel.questions.count)"
    }
    
    // Мемоизированные индексы ответов для избежания повторных вычислений
    private var answerIndices: [String: Int] {
        guard let question = viewModel.currentQuestion else { return [:] }
        return Dictionary(uniqueKeysWithValues: 
            question.answers.enumerated().map { ($1.id, $0) }
        )
    }
    
    var body: some View {
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
            
            VStack(spacing: 0) {
                // Header with progress and score
                VStack(spacing: DesignTokens.Spacing.lg) {
                    HStack {
                        LocalizedText("mistakes.title")
                            .font(DesignTokens.Typography.secondaryRegular)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        
                        Spacer()
                        
                        LocalizedText("mistakes.score")
                            .font(DesignTokens.Typography.secondaryRegular)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    
                    HStack {
                        Text(progressText)
                            .font(DesignTokens.Typography.h1)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(viewModel.correctAnswers)")
                            .font(DesignTokens.Typography.h1)
                            .foregroundStyle(DesignTokens.Colors.statusGreen)
                    }
                    
                    // Progress bar
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.Colors.iconRed))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding(DesignTokens.Spacing.xxl)
                .background(DesignTokens.Colors.cardBackground)
            
                // Question content
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.xxl) {
                        // Question text
                        if let question = viewModel.currentQuestion {
                            VStack(spacing: DesignTokens.Spacing.lg) {
                                Text(question.text)
                                    .font(DesignTokens.Typography.h2)
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding(DesignTokens.Spacing.xxl)
                                    .frame(maxWidth: .infinity)
                                    .cardStyle(
                                        cornerRadius: DesignTokens.CornerRadius.medium,
                                        borderColor: DesignTokens.Colors.borderDefault,
                                        shadowColor: Color.black.opacity(0.24),
                                        shadowRadius: 8,
                                        shadowYOffset: 4
                                    )
                                    .accessibilityLabel("Question: \(question.text)")
                                    .accessibilityAddTraits(.isHeader)
                                    .dynamicTypeSize(.large)
                                
                                // Category and difficulty
                                HStack {
                                    Label(question.category, systemImage: "tag")
                                        .font(DesignTokens.Typography.label)
                                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Label(question.difficulty.localizedName, systemImage: "star.fill")
                                        .font(DesignTokens.Typography.label)
                                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                                }
                                .padding(.horizontal, DesignTokens.Spacing.sm)
                                
                                // Mistake indicator
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(DesignTokens.Colors.iconRed)
                                    Text(localizationProvider.localizedString(for: "mistakes.wrongAnswer"))
                                        .font(DesignTokens.Typography.label)
                                        .foregroundColor(DesignTokens.Colors.iconRed)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .padding(DesignTokens.Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                        .fill(DesignTokens.Colors.iconRed.opacity(0.1))
                                )
                                .padding(.horizontal, DesignTokens.Spacing.sm)
                            }
                            
                            // Answer options
                            VStack(spacing: DesignTokens.Spacing.md) {
                                ForEach(question.answers, id: \.id) { answer in
                                    let index = answerIndices[answer.id] ?? 0
                                    AnswerButton(
                                        answer: answer,
                                        index: index,
                                        isSelected: viewModel.selectedAnswerIndex == index,
                                        isCorrect: index == question.correctIndex,
                                        isAnswerSelected: viewModel.isAnswerSelected,
                                        action: {
                                            viewModel.selectAnswer(at: index)
                                        }
                                    )
                                    .accessibilityLabel("Answer option \(index + 1)")
                                    .accessibilityHint("Double tap to select this answer")
                                    .accessibilityAddTraits(viewModel.selectedAnswerIndex == index ? .isSelected : [])
                                }
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.xxl)
                }
            
                // Stop button at the bottom
                VStack(spacing: 0) {
                    Divider()
                        .background(DesignTokens.Colors.borderSubtle)
                    
                    Button(action: {
                        showingStopConfirm = true
                    }) {
                        HStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: DesignTokens.Sizes.iconMedium))
                            Text(localizationProvider.localizedString(for: "mistakes.stop"))
                                .font(DesignTokens.Typography.secondarySemibold)
                        }
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .cardStyle(
                            cornerRadius: DesignTokens.CornerRadius.medium,
                            fillColor: DesignTokens.Colors.iconRed,
                            borderColor: DesignTokens.Colors.iconRed.opacity(0.4),
                            shadowColor: Color.black.opacity(0.24),
                            shadowRadius: 8,
                            shadowYOffset: 4
                        )
                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                        .padding(.vertical, DesignTokens.Spacing.md)
                    }
                    .accessibilityLabel("Stop mistakes review")
                    .accessibilityHint("Double tap to stop the mistakes review")
                    .background(DesignTokens.Colors.cardBackground)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(DesignTokens.Colors.background1, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert(
            "mistakes.stop.confirm.title".localized,
            isPresented: $showingStopConfirm
        ) {
            Button("mistakes.stop.confirm.cancel".localized, role: .cancel) {
                showingStopConfirm = false
            }
            Button("mistakes.stop.confirm.ok".localized, role: .destructive) {
                viewModel.restartQuiz()
            }
        } message: {
            Text("mistakes.stop.confirm.message".localized)
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
    MistakesReviewView(viewModel: viewModel)
}
