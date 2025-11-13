//
//  QuizView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI
import UserNotifications

struct QuizView: View {
    @Bindable var viewModel: QuizViewModel
    @State private var showingStopConfirm: Bool = false
    @State private var showingFinishConfirm: Bool = false
    
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
                        LocalizedText("quiz.question")
                            .font(DesignTokens.Typography.secondaryRegular)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        
                        Spacer()
                        
                        LocalizedText("quiz.score")
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
                        .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.Colors.iconBlue))
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
            
                // Finish button at the bottom
                VStack(spacing: 0) {
                    Divider()
                        .background(DesignTokens.Colors.borderSubtle)
                    
                    Button(action: {
                        showingFinishConfirm = true
                    }) {
                        HStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: DesignTokens.Sizes.iconMedium))
                            Text("quiz.finish".localized)
                                .font(DesignTokens.Typography.secondarySemibold)
                        }
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .cardStyle(
                            cornerRadius: DesignTokens.CornerRadius.medium,
                            fillColor: DesignTokens.Colors.statusGreen,
                            borderColor: DesignTokens.Colors.statusGreen.opacity(0.4),
                            shadowColor: Color.black.opacity(0.24),
                            shadowRadius: 8,
                            shadowYOffset: 4
                        )
                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                        .padding(.vertical, DesignTokens.Spacing.md)
                    }
                    .accessibilityLabel("Finish quiz")
                    .accessibilityHint("Double tap to finish the current quiz")
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
            "quiz.finish.confirm.title".localized,
            isPresented: $showingFinishConfirm
        ) {
            Button("quiz.finish.confirm.cancel".localized, role: .cancel) {
                showingFinishConfirm = false
            }
            Button("quiz.finish.confirm.ok".localized, role: .destructive) {
                viewModel.forceFinishQuiz()
            }
        } message: {
            Text("quiz.finish.confirm.message".localized)
        }
        .alert(
            "quiz.stop.confirm.title".localized,
            isPresented: $showingStopConfirm
        ) {
            Button("quiz.stop.confirm.cancel".localized, role: .cancel) {
                showingStopConfirm = false
            }
            Button("quiz.stop.confirm.ok".localized, role: .destructive) {
                viewModel.restartQuiz()
            }
        } message: {
            Text("quiz.stop.confirm.message".localized)
        }
        .onAppear {
            // Clear app badge when quiz starts
            if #available(iOS 17.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
            } else {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
}

struct AnswerButton: View {
    let answer: Answer
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let isAnswerSelected: Bool
    let action: () -> Void
    
    private var buttonColor: Color {
        if !isAnswerSelected {
            return DesignTokens.Colors.iconBlue
        } else if isSelected {
            return isCorrect ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.iconRed
        } else if isCorrect {
            return DesignTokens.Colors.statusGreen
        } else {
            return DesignTokens.Colors.textTertiary
        }
    }
    
    private var backgroundColor: Color {
        if !isAnswerSelected {
            return DesignTokens.Colors.progressCard
        } else if isSelected {
            return isCorrect ? DesignTokens.Colors.statusGreen.opacity(0.15) : DesignTokens.Colors.iconRed.opacity(0.15)
        } else if isCorrect {
            return DesignTokens.Colors.statusGreen.opacity(0.15)
        } else {
            return DesignTokens.Colors.progressCard
        }
    }
    
    private var buttonStyle: some ButtonStyle {
        AnswerButtonStyle(
            color: buttonColor,
            isSelected: isSelected,
            isAnswerSelected: isAnswerSelected
        )
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Text(answer.text)
                    .font(DesignTokens.Typography.bodyRegular)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isAnswerSelected && isCorrect && isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                        .foregroundColor(DesignTokens.Colors.statusGreen)
                } else if isAnswerSelected && !isCorrect && isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                        .foregroundColor(DesignTokens.Colors.iconRed)
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .stroke(buttonColor, lineWidth: isSelected ? 2 : 1)
                    )
            )
            .shadow(
                color: isSelected ? buttonColor.opacity(0.3) : DesignTokens.Shadows.card,
                radius: isSelected ? 8 : DesignTokens.Shadows.cardRadius,
                y: DesignTokens.Shadows.cardY
            )
        }
        .buttonStyle(buttonStyle)
        .disabled(isAnswerSelected)
    }
}

struct AnswerButtonStyle: ButtonStyle {
    let color: Color
    let isSelected: Bool
    let isAnswerSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.3), value: isAnswerSelected)
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
    let quizUseCase = QuizUseCase(
        questionsRepository: QuestionsRepository(),
        adaptiveEngine: adaptiveEngine,
        profileManager: profileManager
    )
    let viewModel = QuizViewModel(
        quizUseCase: quizUseCase,
        statsManager: statsManager,
        settingsManager: SettingsManager()
    )
    return QuizView(viewModel: viewModel)
}
