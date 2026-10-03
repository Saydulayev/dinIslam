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
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var showingStopConfirm: Bool = false
    @State private var showingFinishConfirm: Bool = false
    
    init(viewModel: QuizViewModel) {
        _viewModel = Bindable(viewModel)
    }
    
    private static let questionTopAnchor = "questionTop"
    
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
            
            // Пока вопросы не загружены, показываем только загрузку — без «1 / 0» и кнопки «Завершить»
            if viewModel.isLoading || viewModel.questions.isEmpty {
                LoadingCardView()
            } else {
                VStack(spacing: 0) {
                    // Header with progress and score
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        HStack {
                            LocalizedText("quiz.question")
                                .font(DesignTokens.Typography.label)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        
                            Spacer()
                        
                            LocalizedText("quiz.score")
                                .font(DesignTokens.Typography.label)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                    
                        HStack {
                            Text(progressText)
                                .font(DesignTokens.Typography.secondarySemibold)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                        
                            Spacer()
                        
                            Text("\(viewModel.correctAnswers)")
                                .font(DesignTokens.Typography.secondarySemibold)
                                .foregroundStyle(DesignTokens.Colors.statusGreen)
                        }
                    
                        // Progress bar
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.Colors.iconBlue))
                            .scaleEffect(x: 1, y: 1.5, anchor: .center)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    // Убираем фон, чтобы был виден градиент как на главном экране
            
                    // Question content
                    ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: DesignTokens.Spacing.xxl) {
                            // Question text
                            if let question = viewModel.currentQuestion {
                                VStack(spacing: DesignTokens.Spacing.lg) {
                                    Text(question.text)
                                        .id(Self.questionTopAnchor)
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
                                    }
                                }
                                
                                // С VoiceOver вопрос не сменяется сам — переход по кнопке
                                if viewModel.isAnswerSelected && !viewModel.advancesAutomatically {
                                    Button(action: viewModel.nextQuestion) {
                                        Label(
                                            (viewModel.isLastQuestion ? "quiz.showResult" : "quiz.next").localized,
                                            systemImage: "arrow.right"
                                        )
                                        .font(DesignTokens.Typography.secondarySemibold)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                    }
                                    .foregroundStyle(DesignTokens.Colors.iconBlue)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                            .stroke(DesignTokens.Colors.iconPurpleLight.opacity(0.5), lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                        .padding(DesignTokens.Spacing.xxl)
                    }
                    .onChange(of: viewModel.currentQuestionIndex) { _, _ in
                        scrollProxy.scrollTo(Self.questionTopAnchor, anchor: .top)
                    }
                    .onChange(of: viewModel.isAnswerSelected) { _, isAnswerSelected in
                        guard isAnswerSelected,
                              let question = viewModel.currentQuestion,
                              let selectedIndex = viewModel.selectedAnswerIndex else { return }
                        AnswerAnnouncement.post(for: question, selectedIndex: selectedIndex)
                    }
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
                            .padding(.horizontal, DesignTokens.Spacing.xxl)
                            .padding(.vertical, DesignTokens.Spacing.lg)
                        }
                        // Убираем фон, чтобы был виден градиент как на главном экране
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.clear, for: .navigationBar) // прозрачный toolbar для градиента
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
        .onChange(of: voiceOverEnabled) { _, isEnabled in
            viewModel.advancesAutomatically = !isEnabled
        }
        .onAppear {
            viewModel.advancesAutomatically = !voiceOverEnabled
            
            // Clear app badge when quiz starts
            if #available(iOS 17.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
            } else {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
}

// MARK: - Loading Card
struct LoadingCardView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.iconBlue))
                .scaleEffect(1.5)
            
            Text("quiz.loading".localized)
                .font(DesignTokens.Typography.bodyRegular)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.xxl)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            return DesignTokens.Colors.iconBlue.opacity(0.15)
        } else if isSelected {
            return isCorrect ? DesignTokens.Colors.statusGreen.opacity(0.2) : DesignTokens.Colors.iconRed.opacity(0.2)
        } else if isCorrect {
            return DesignTokens.Colors.statusGreen.opacity(0.2)
        } else {
            return DesignTokens.Colors.cardBackground
        }
    }
    
    // Состояние ответа для VoiceOver: цвет и иконки ему недоступны
    private var accessibilityStatus: String {
        guard isAnswerSelected else { return "" }
        if isSelected {
            return isCorrect
                ? "accessibility.answer.selectedCorrect".localized
                : "accessibility.answer.selectedWrong".localized
        }
        return isCorrect ? "accessibility.answer.correct".localized : ""
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
                
                // Правильный ответ отмечается иконкой и тогда, когда выбран другой вариант
                if isAnswerSelected && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                        .foregroundColor(DesignTokens.Colors.statusGreen)
                        .accessibilityHidden(true)
                } else if isAnswerSelected && isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                        .foregroundColor(DesignTokens.Colors.iconRed)
                        .accessibilityHidden(true)
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
        .accessibilityValue(accessibilityStatus)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Answer Announcement
enum AnswerAnnouncement {
    /// Озвучивает результат ответа для VoiceOver
    static func post(for question: Question, selectedIndex: Int) {
        let text: String
        if selectedIndex == question.correctIndex {
            text = "accessibility.announce.correct".localized
        } else if question.answers.indices.contains(question.correctIndex) {
            text = "accessibility.announce.wrongWithAnswer".localized(
                arguments: question.answers[question.correctIndex].text
            )
        } else {
            text = "accessibility.announce.wrong".localized
        }
        
        var message = AttributedString(text)
        message.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(message).post()
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
    let viewModel = QuizViewModel(
        quizUseCase: quizUseCase,
        statsManager: statsManager,
        settingsManager: SettingsManager()
    )
    QuizView(viewModel: viewModel)
}
