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
            
            VStack(spacing: 0) {
                // Header with timer and progress
                ExamHeaderView(viewModel: viewModel)
                
                // Main content
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
                                    .background(
                                        // Прозрачная рамка с фиолетовым свечением (как на главном экране)
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
                                    )
                                    .accessibilityLabel("Question: \(question.text)")
                                    .accessibilityAddTraits(.isHeader)
                                    .dynamicTypeSize(.large)
                                
                                // Category
                                HStack {
                                    Label(question.category, systemImage: "tag")
                                        .font(DesignTokens.Typography.label)
                                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, DesignTokens.Spacing.sm)
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
                                    .accessibilityLabel("Answer option \(index + 1)")
                                    .accessibilityHint("Double tap to select this answer")
                                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                                }
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.xxl)
                }
                
                // Fixed action buttons at the bottom
                VStack(spacing: 0) {
                    Divider()
                        .background(DesignTokens.Colors.borderSubtle)
                    
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
                                .foregroundColor(DesignTokens.Colors.iconOrange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    // Прозрачная рамка с фиолетовым свечением (как на главном экране)
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
                                )
                            }
                            .accessibilityLabel("Skip question")
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
                            .foregroundColor(DesignTokens.Colors.iconBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                // Прозрачная рамка с фиолетовым свечением (как на главном экране)
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
                            )
                        }
                        .accessibilityLabel(viewModel.state == .active(.paused) ? "Resume exam" : "Pause exam")
                        
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
                            .foregroundColor(DesignTokens.Colors.statusGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                // Прозрачная рамка с фиолетовым свечением (как на главном экране)
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
                            )
                        }
                        .accessibilityLabel("Finish exam")
                        .accessibilityHint("Double tap to finish the current exam")
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    .padding(.vertical, DesignTokens.Spacing.lg)
                    // Убираем фон, чтобы был виден градиент как на главном экране
                }
            }
        }
        .navigationTitle("exam.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.clear, for: .navigationBar) // прозрачный toolbar для градиента
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
        .padding(.horizontal, DesignTokens.Spacing.xxl)
        .padding(.vertical, DesignTokens.Spacing.lg)
        // Убираем фон, чтобы был виден градиент как на главном экране
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

