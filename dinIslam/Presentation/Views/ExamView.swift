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
    
    private var currentAnswer: ExamAnswer? {
        guard let question = viewModel.currentQuestion else { return nil }
        return viewModel.answers[question.id]
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            switch viewModel.state {
            case .idle, .active(.loading):
                LoadingCardView()
            case .error:
                ExamErrorView(
                    message: viewModel.errorMessage,
                    onRetry: { Task { await viewModel.retake() } },
                    onExit: onExit
                )
            default:
                examContent
            }
        }
        .navigationTitle("exam.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $showingResult) {
            if let result = viewModel.examResult {
                ExamResultView(
                    result: result,
                    viewModel: viewModel,
                    onRetake: {
                        showingResult = false
                        Task { await viewModel.retake() }
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
            case .active(.timeUp):
                AccessibilityNotification.Announcement("exam.timeUp".localized).post()
            default:
                break
            }
        }
    }
    
    // MARK: - Exam Content
    private var examContent: some View {
        VStack(spacing: 0) {
            // Header with timer and progress
            ExamHeaderView(viewModel: viewModel)
            
            // Main content
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxl) {
                    if viewModel.state == .active(.paused) {
                        // На паузе вопрос скрыт: таймер стоит, отвечать нельзя
                        ExamPausedView(onResume: viewModel.resumeExam)
                    } else if let question = viewModel.currentQuestion {
                        VStack(spacing: DesignTokens.Spacing.lg) {
                            Text(question.text)
                                .font(DesignTokens.Typography.h2)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(DesignTokens.Spacing.xxl)
                                .frame(maxWidth: .infinity)
                                .glowBorder()
                                .accessibilityAddTraits(.isHeader)
                            
                            // Category
                            if question.category != QuestionCategory.generalId {
                                HStack {
                                    Label(
                                        QuestionCategory.displayName(for: question.category),
                                        systemImage: QuestionCategory.icon(for: question.category)
                                    )
                                    .font(DesignTokens.Typography.label)
                                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                                    Spacer()
                                }
                                .padding(.horizontal, DesignTokens.Spacing.sm)
                            }
                        }
                        
                        if viewModel.state == .active(.timeUp) {
                            Label("exam.timeUp".localized, systemImage: "timer")
                                .font(DesignTokens.Typography.secondarySemibold)
                                .foregroundStyle(DesignTokens.Colors.error)
                                .padding(.horizontal, DesignTokens.Spacing.lg)
                                .padding(.vertical, DesignTokens.Spacing.sm)
                                .background(
                                    Capsule()
                                        .fill(DesignTokens.Colors.error.opacity(0.15))
                                )
                                .transition(.opacity)
                        }
                        
                        // Answer options
                        VStack(spacing: DesignTokens.Spacing.md) {
                            ForEach(Array(question.answers.enumerated()), id: \.element.id) { index, answer in
                                let isAnswered = viewModel.answers[question.id] != nil
                                let isSelected = viewModel.answers[question.id]?.selectedAnswerIndex == index
                                
                                AnswerButton(
                                    answer: answer,
                                    index: index,
                                    isSelected: isSelected,
                                    isCorrect: index == question.correctIndex,
                                    isAnswerSelected: isAnswered,
                                    action: {
                                        viewModel.selectAnswer(at: index)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(DesignTokens.Spacing.xxl)
            }
            .onChange(of: currentAnswer) { _, answer in
                guard let answer,
                      let selectedIndex = answer.selectedAnswerIndex,
                      let question = viewModel.currentQuestion,
                      question.id == answer.questionId else { return }
                AnswerAnnouncement.post(for: question, selectedIndex: selectedIndex)
            }
            
            // Fixed action buttons at the bottom
            VStack(spacing: 0) {
                Divider()
                    .overlay(DesignTokens.Colors.borderSubtle)
                
                HStack(spacing: DesignTokens.Spacing.md) {
                    // Skip button
                    if viewModel.canSkipQuestion {
                        Button(action: {
                            viewModel.skipQuestion()
                        }) {
                            VStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                                Text("exam.skip".localized)
                                    .font(DesignTokens.Typography.label)
                            }
                        }
                        .buttonStyle(DSButtonStyle(role: .warning))
                        .disabled(viewModel.state != .active(.playing))
                    }
                    
                    // Pause/Resume button
                    Button(action: {
                        if viewModel.state == .active(.paused) {
                            viewModel.resumeExam()
                        } else {
                            showingPauseAlert = true
                        }
                    }) {
                        VStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: viewModel.state == .active(.paused) ? "play.fill" : "pause.fill")
                                .font(.system(size: DesignTokens.Sizes.iconMedium))
                            Text(viewModel.state == .active(.paused) ? "exam.resume".localized : "exam.pause".localized)
                                .font(DesignTokens.Typography.label)
                        }
                    }
                    .buttonStyle(DSButtonStyle())
                    .disabled(viewModel.state != .active(.paused) && !viewModel.canPause)

                    // Finish button
                    Button(action: {
                        showingStopAlert = true
                    }) {
                        VStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: DesignTokens.Sizes.iconMedium))
                            Text("quiz.finish".localized)
                                .font(DesignTokens.Typography.label)
                        }
                    }
                    .buttonStyle(DSButtonStyle(role: .success))
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.vertical, DesignTokens.Spacing.lg)
                // Убираем фон, чтобы был виден градиент как на главном экране
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
                        Image(systemName: viewModel.state == .active(.paused) ? "pause.fill" : "timer")
                            .font(.system(size: DesignTokens.Sizes.iconSmall))
                            .foregroundStyle(timerColor)

                        Text(viewModel.timeRemainingFormatted)
                            .font(DesignTokens.Typography.secondarySemibold)
                            .foregroundStyle(timerColor)
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
        // Убираем фон, чтобы был виден градиент как на главном экране
    }
    
    private var timerColor: Color {
        switch viewModel.timerUrgency {
        case .critical:
            return DesignTokens.Colors.error
        case .warning:
            return DesignTokens.Colors.warning
        case .normal:
            return DesignTokens.Colors.iconBlue
        }
    }
    
    private var timerBackgroundColor: Color {
        timerColor.opacity(0.15)
    }
}


// MARK: - Exam Paused View
struct ExamPausedView: View {
    let onResume: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: DesignTokens.Sizes.iconDisplay))
                .foregroundStyle(DesignTokens.Colors.iconBlue)
                .accessibilityHidden(true)
            
            Text("exam.paused.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            Text("exam.paused.message".localized)
                .font(DesignTokens.Typography.bodyRegular)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: onResume) {
                Label("exam.resume".localized, systemImage: "play.fill")
                    .font(DesignTokens.Typography.secondarySemibold)
            }
            .buttonStyle(DSButtonStyle())
        }
        .padding(DesignTokens.Spacing.xxl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .stroke(DesignTokens.Colors.iconPurpleLight.opacity(0.35), lineWidth: 1.5)
        )
    }
}

// MARK: - Exam Error View
struct ExamErrorView: View {
    let message: String?
    let onRetry: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(DesignTokens.Colors.warning)
                .accessibilityHidden(true)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("exam.error.title".localized)
                    .font(DesignTokens.Typography.h2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                if let message, !message.isEmpty {
                    Text(message)
                        .font(DesignTokens.Typography.bodyRegular)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Button(action: onRetry) {
                    Label("exam.error.retry".localized, systemImage: "arrow.clockwise")
                        .font(DesignTokens.Typography.secondarySemibold)
                }
                .buttonStyle(DSButtonStyle())
                
                Button(action: onExit) {
                    Label("result.backToStart".localized, systemImage: "house.fill")
                        .font(DesignTokens.Typography.secondarySemibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ExamView(viewModel: ExamViewModel(
        examUseCase: ExamUseCase(
            questionsRepository: EnhancedQuestionsRepository(),
            examStatisticsManager: ExamStatisticsManager()
        ),
        examStatisticsManager: ExamStatisticsManager(),
        settingsManager: SettingsManager()
    ), onExit: {})
}

