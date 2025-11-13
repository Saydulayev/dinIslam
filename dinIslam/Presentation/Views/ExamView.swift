//
//  ExamView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct ExamView: View {
    @Bindable var viewModel: ExamViewModel
    let onExit: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingPauseAlert = false
    @State private var showingStopAlert = false
    @State private var showingResult = false
    
    init(viewModel: ExamViewModel, onExit: @escaping () -> Void) {
        _viewModel = Bindable(viewModel)
        self.onExit = onExit
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
                // Header with timer and progress
                ExamHeaderView(viewModel: viewModel)
                
                // Main content
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.xxl) {
                        // Question content
                        ExamQuestionView(viewModel: viewModel)
                        
                        // Answer options
                        ExamAnswersView(viewModel: viewModel)
                        
                        // Skip button (if available)
                        if viewModel.canSkipQuestion {
                            Button(action: {
                                viewModel.skipQuestion()
                            }) {
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                                    Text("exam.skip".localized)
                                        .font(DesignTokens.Typography.secondarySemibold)
                                }
                                .foregroundColor(DesignTokens.Colors.iconOrange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .cardStyle(
                                    cornerRadius: DesignTokens.CornerRadius.medium,
                                    fillColor: DesignTokens.Colors.progressCard,
                                    borderColor: DesignTokens.Colors.iconOrange.opacity(0.35),
                                    shadowColor: Color.black.opacity(0.24),
                                    shadowRadius: 8,
                                    shadowYOffset: 4
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                        .stroke(DesignTokens.Colors.iconOrange, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    .padding(.top, DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }
                
                // Fixed finish button at the bottom
                VStack(spacing: 0) {
                    Divider()
                        .background(DesignTokens.Colors.borderSubtle)
                    
                    Button(action: {
                        showingStopAlert = true
                    }) {
                        HStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: DesignTokens.Sizes.iconMedium))
                            Text("exam.finish".localized)
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
                    .accessibilityLabel("Finish exam")
                    .accessibilityHint("Double tap to finish the current exam")
                    .background(DesignTokens.Colors.cardBackground)
                }
            }
        }
        .navigationTitle("exam.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(DesignTokens.Colors.background1, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(viewModel.state == .active(.paused) ? "exam.resume".localized : "exam.pause".localized) {
                    if viewModel.state == .active(.paused) {
                        viewModel.resumeExam()
                    } else {
                        showingPauseAlert = true
                    }
                }
                .foregroundColor(DesignTokens.Colors.iconBlue)
            }
        }
        .navigationDestination(isPresented: $showingResult) {
            if let result = viewModel.examResult {
                ExamResultView(
                    result: result,
                    viewModel: viewModel,
                    onRetake: {
                        showingResult = false
                        viewModel.restartExam()
                    },
                    onBackToMenu: {
                        showingResult = false
                        onExit()
                    }
                )
            }
        }
        .alert("exam.pause.title".localized, isPresented: $showingPauseAlert) {
            Button("exam.pause.cancel".localized, role: .cancel) { }
            Button("exam.pause.confirm".localized) {
                viewModel.pauseExam()
            }
        } message: {
            Text("exam.pause.message".localized)
        }
        .alert("exam.finish.title".localized, isPresented: $showingStopAlert) {
            Button("exam.finish.cancel".localized, role: .cancel) { }
            Button("exam.finish.confirm".localized, role: .destructive) {
                viewModel.finishExam()
                showingResult = true
            }
        } message: {
            Text("exam.finish.message".localized)
        }
        .onChange(of: viewModel.state) { _, newState in
            switch newState {
            case .completed:
                showingResult = true
            default:
                break
            }
        }
    }
}

// MARK: - Exam Header View
struct ExamHeaderView: View {
    let viewModel: ExamViewModel
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Progress bar
            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.Colors.iconBlue))
                .scaleEffect(x: 1, y: 2)
            
            HStack {
                // Question counter
                Text("\(viewModel.currentQuestionIndex + 1) / \(viewModel.questions.count)")
                    .font(DesignTokens.Typography.h1)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                // Timer
                if viewModel.configuration.showTimer {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "timer")
                            .font(.system(size: DesignTokens.Sizes.iconSmall))
                            .foregroundColor(timerColor)
                        
                        Text(viewModel.timeRemainingFormatted)
                            .font(DesignTokens.Typography.secondarySemibold)
                            .foregroundColor(timerColor)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                            .fill(timerBackgroundColor)
                    )
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xxl)
        .padding(.vertical, DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.cardBackground)
    }
    
    private var timerColor: Color {
        if viewModel.timeRemaining <= 10 {
            return DesignTokens.Colors.iconRed
        } else if viewModel.timeRemaining <= 20 {
            return DesignTokens.Colors.iconOrange
        } else {
            return DesignTokens.Colors.iconBlue
        }
    }
    
    private var timerBackgroundColor: Color {
        if viewModel.timeRemaining <= 10 {
            return DesignTokens.Colors.iconRed.opacity(0.15)
        } else if viewModel.timeRemaining <= 20 {
            return DesignTokens.Colors.iconOrange.opacity(0.15)
        } else {
            return DesignTokens.Colors.iconBlue.opacity(0.15)
        }
    }
}

// MARK: - Exam Question View
struct ExamQuestionView: View {
    let viewModel: ExamViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            if let question = viewModel.currentQuestion {
                Text(question.text)
                    .font(DesignTokens.Typography.h2)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                // Category and difficulty
                HStack(spacing: DesignTokens.Spacing.md) {
                    Label(question.category, systemImage: "folder")
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(DesignTokens.Colors.iconBlue.opacity(0.15))
                        )
                    
                    Label(question.difficulty.localizedName, systemImage: "star")
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(DesignTokens.Colors.iconOrange.opacity(0.15))
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.xxl)
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.large)
    }
}

// MARK: - Exam Answers View
struct ExamAnswersView: View {
    let viewModel: ExamViewModel
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            if let question = viewModel.currentQuestion {
                ForEach(Array(question.answers.enumerated()), id: \.element.id) { index, answer in
                    ExamAnswerButton(
                        answer: answer,
                        index: index,
                        isSelected: viewModel.answers[question.id]?.selectedAnswerIndex == index,
                        isCorrect: index == question.correctIndex,
                        isAnswered: viewModel.answers[question.id] != nil,
                        onTap: {
                            viewModel.selectAnswer(at: index)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Exam Answer Button
struct ExamAnswerButton: View {
    let answer: Answer
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let isAnswered: Bool
    let onTap: () -> Void
    
    private var buttonColor: Color {
        if isAnswered {
            // Показываем цвет только для выбранного ответа
            if isSelected {
                return isCorrect ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.iconRed
            } else {
                // Остальные ответы остаются серыми
                return DesignTokens.Colors.textTertiary
            }
        } else {
            return isSelected ? DesignTokens.Colors.iconBlue : DesignTokens.Colors.textTertiary
        }
    }
    
    private var buttonBackground: Color {
        if isAnswered {
            // Показываем фон только для выбранного ответа
            if isSelected {
                return isCorrect ? DesignTokens.Colors.statusGreen.opacity(0.15) : DesignTokens.Colors.iconRed.opacity(0.15)
            } else {
                // Остальные ответы остаются с обычным фоном
                return DesignTokens.Colors.progressCard
            }
        } else {
            return isSelected ? DesignTokens.Colors.iconBlue.opacity(0.15) : DesignTokens.Colors.progressCard
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.lg) {
                // Answer letter
                Text(String(Character(UnicodeScalar(65 + index)!)))
                    .font(DesignTokens.Typography.secondarySemibold)
                    .foregroundColor(buttonColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(buttonColor.opacity(0.2))
                    )
                
                // Answer text
                Text(answer.text)
                    .font(DesignTokens.Typography.bodyRegular)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Status icon - показываем только для выбранного ответа
                if isAnswered && isSelected {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(buttonColor)
                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(buttonBackground)
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
        .disabled(isAnswered)
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    ExamView(viewModel: ExamViewModel(
        examUseCase: ExamUseCase(
            questionsRepository: QuestionsRepository(),
            examStatisticsManager: ExamStatisticsManager()
        ),
        examStatisticsManager: ExamStatisticsManager(),
        settingsManager: SettingsManager()
    ), onExit: {})
}

