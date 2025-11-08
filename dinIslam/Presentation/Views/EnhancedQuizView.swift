//
//  EnhancedQuizView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI
import UserNotifications

struct EnhancedQuizView: View {
    @Bindable var viewModel: QuizViewModel
    @State private var showingStopConfirm: Bool = false
    
    // Accessibility and UX enhancements
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.layoutDirection) private var layoutDirection
    
    init(viewModel: QuizViewModel) {
        _viewModel = Bindable(viewModel)
    }
    
    // MARK: - Computed Properties
    private var progressText: String {
        "\(viewModel.currentQuestionIndex + 1) / \(viewModel.questions.count)"
    }
    
    private var accessibilityProgressText: String {
        "Question \(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count)"
    }
    
    // Мемоизированные индексы ответов для избежания повторных вычислений
    private var answerIndices: [String: Int] {
        guard let question = viewModel.currentQuestion else { return [:] }
        return Dictionary(uniqueKeysWithValues: 
            question.answers.enumerated().map { ($1.id, $0) }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress and score
            VStack(spacing: 16) {
                HStack {
                    LocalizedText("quiz.question")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .dynamicTypeSize(.accessibility1)
                    
                    Spacer()
                    
                    LocalizedText("quiz.score")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .dynamicTypeSize(.accessibility1)
                }
                
                HStack {
                    Text(progressText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .dynamicTypeSize(.accessibility1)
                        .accessibilityLabel(accessibilityProgressText)
                    
                    Spacer()
                    
                    Text("\(viewModel.correctAnswers)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                        .dynamicTypeSize(.accessibility1)
                        .accessibilityLabel("Score: \(viewModel.correctAnswers)")
                }
                
                // Progress bar with accessibility
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .accessibilityLabel("Progress: \(Int(viewModel.progress * 100))%")
                    .accessibilityValue("\(viewModel.currentQuestionIndex + 1) of \(viewModel.questions.count) questions completed")
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Question content
            ScrollView {
                VStack(spacing: 24) {
                    // Question text
                    if let question = viewModel.currentQuestion {
                        VStack(spacing: 16) {
                            Text(question.text)
                                .font(.title2)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .accessibilityLabel("Question: \(question.text)")
                                .accessibilityAddTraits(.isHeader)
                                .dynamicTypeSize(.accessibility1)
                            
                            // Category and difficulty
                            HStack {
                                Label(question.category, systemImage: "tag")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .dynamicTypeSize(.accessibility1)
                                    .accessibilityLabel("Category: \(question.category)")
                                
                                Spacer()
                                
                                Label(question.difficulty.localizedName, systemImage: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .dynamicTypeSize(.accessibility1)
                                    .accessibilityLabel("Difficulty: \(question.difficulty.localizedName)")
                            }
                            .padding(.horizontal)
                        }
                        
                        // Answer options
                        VStack(spacing: 12) {
                            ForEach(question.answers, id: \.id) { answer in
                                let index = answerIndices[answer.id] ?? 0
                                EnhancedAnswerButton(
                                    answer: answer,
                                    index: index,
                                    isSelected: viewModel.selectedAnswerIndex == index,
                                    isCorrect: index == question.correctIndex,
                                    isAnswerSelected: viewModel.isAnswerSelected,
                                    differentiateWithoutColor: differentiateWithoutColor,
                                    action: {
                                        viewModel.selectAnswer(at: index)
                                    }
                                )
                                .accessibilityLabel("Answer option \(index + 1): \(answer.text)")
                                .accessibilityHint("Double tap to select this answer")
                                .accessibilityAddTraits(viewModel.selectedAnswerIndex == index ? .isSelected : [])
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Stop button at the bottom
            VStack(spacing: 0) {
                Divider()
                    .background(.separator)
                
                Button(action: {
                    showingStopConfirm = true
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("quiz.stop".localized)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.red.gradient, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .accessibilityLabel("Stop quiz")
                .accessibilityHint("Double tap to stop the current quiz")
                .accessibilityAddTraits(.isButton)
                .background(.ultraThinMaterial)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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

struct EnhancedAnswerButton: View {
    let answer: Answer
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let isAnswerSelected: Bool
    let differentiateWithoutColor: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var buttonColor: Color {
        if !isAnswerSelected {
            return .blue
        } else if isSelected {
            return isCorrect ? .green : .red
        } else if isCorrect {
            return .green
        } else {
            return .gray
        }
    }
    
    private var checkmarkColor: Color {
        if isCorrect {
            // Адаптивный цвет для правильного ответа - более контрастный в светлой теме
            return colorScheme == .light ? Color(red: 0.0, green: 0.6, blue: 0.2) : .green
        } else {
            // Адаптивный цвет для неправильного ответа - более контрастный в светлой теме
            return colorScheme == .light ? Color(red: 0.8, green: 0.0, blue: 0.0) : .red
        }
    }
    
    private var buttonStyle: some ButtonStyle {
        EnhancedAnswerButtonStyle(
            color: buttonColor,
            isSelected: isSelected,
            isAnswerSelected: isAnswerSelected,
            differentiateWithoutColor: differentiateWithoutColor
        )
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(answer.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .dynamicTypeSize(.accessibility1)
                
                Spacer()
                
                if isAnswerSelected && isCorrect && isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(checkmarkColor)
                } else if isAnswerSelected && !isCorrect && isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(checkmarkColor)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(buttonColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(buttonColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(buttonStyle)
        .disabled(isAnswerSelected)
    }
}

struct EnhancedAnswerButtonStyle: ButtonStyle {
    let color: Color
    let isSelected: Bool
    let isAnswerSelected: Bool
    let differentiateWithoutColor: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.1), 
                value: configuration.isPressed
            )
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.3), 
                value: isAnswerSelected
            )
    }
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
}

#Preview {
    let viewModel = QuizViewModel(quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository()), statsManager: StatsManager(), settingsManager: SettingsManager())
    EnhancedQuizView(viewModel: viewModel)
}
