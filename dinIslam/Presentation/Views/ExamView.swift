//
//  ExamView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct ExamView: View {
    @State private var viewModel: ExamViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingPauseAlert = false
    @State private var showingStopAlert = false
    @State private var showingResult = false
    
    init(viewModel: ExamViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with timer and progress
                ExamHeaderView(viewModel: viewModel)
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Question content
                        ExamQuestionView(viewModel: viewModel)
                        
                        // Answer options
                        ExamAnswersView(viewModel: viewModel)
                        
                        // Skip button (if available) - only skip button here
                        if viewModel.canSkipQuestion {
                            Button(action: {
                                viewModel.skipQuestion()
                            }) {
                                HStack {
                                    Image(systemName: "forward.fill")
                                    Text("exam.skip".localized)
                                }
                                .font(.headline)
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
                
                // Fixed finish button at the bottom (like in QuizView)
                VStack(spacing: 0) {
                    Divider()
                        .background(.separator)
                    
                    Button(action: {
                        showingStopAlert = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("exam.finish".localized)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.green.gradient, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .accessibilityLabel("Finish exam")
                    .accessibilityHint("Double tap to finish the current exam")
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("exam.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.state == .active(.paused) ? "exam.resume".localized : "exam.pause".localized) {
                        if viewModel.state == .active(.paused) {
                            viewModel.resumeExam()
                        } else {
                            showingPauseAlert = true
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationDestination(isPresented: $showingResult) {
                if let result = viewModel.examResult {
                    ExamResultView(result: result, viewModel: viewModel)
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
                if case .completed = newState {
                    showingResult = true
                }
            }
        }
    }
}

// MARK: - Exam Header View
struct ExamHeaderView: View {
    let viewModel: ExamViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2)
            
            HStack {
                // Question counter
                Text("\(viewModel.currentQuestionIndex + 1) / \(viewModel.questions.count)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Timer
                if viewModel.configuration.showTimer {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .foregroundColor(timerColor)
                        
                        Text(viewModel.timeRemainingFormatted)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(timerColor)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(timerBackgroundColor, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    private var timerColor: Color {
        if viewModel.timeRemaining <= 10 {
            return .red
        } else if viewModel.timeRemaining <= 20 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var timerBackgroundColor: Color {
        if viewModel.timeRemaining <= 10 {
            return .red.opacity(0.1)
        } else if viewModel.timeRemaining <= 20 {
            return .orange.opacity(0.1)
        } else {
            return .blue.opacity(0.1)
        }
    }
}

// MARK: - Exam Question View
struct ExamQuestionView: View {
    let viewModel: ExamViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let question = viewModel.currentQuestion {
                Text(question.text)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // Category and difficulty
                HStack(spacing: 12) {
                    Label(question.category, systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    
                    Label(question.difficulty.localizedName, systemImage: "star")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Exam Answers View
struct ExamAnswersView: View {
    let viewModel: ExamViewModel
    
    var body: some View {
        VStack(spacing: 12) {
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
            if isSelected {
                return isCorrect ? .green : .red
            } else if isCorrect {
                return .green
            } else {
                return .gray
            }
        } else {
            return isSelected ? .blue : .gray
        }
    }
    
    private var buttonBackground: Color {
        if isAnswered {
            if isSelected {
                return isCorrect ? .green.opacity(0.1) : .red.opacity(0.1)
            } else if isCorrect {
                return .green.opacity(0.1)
            } else {
                return .gray.opacity(0.05)
            }
        } else {
            return isSelected ? .blue.opacity(0.1) : .gray.opacity(0.05)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Answer letter
                Text(String(Character(UnicodeScalar(65 + index)!)))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(buttonColor)
                    .frame(width: 32, height: 32)
                    .background(buttonColor.opacity(0.2), in: Circle())
                
                // Answer text
                Text(answer.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Status icon
                if isAnswered {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(buttonColor)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(buttonBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(buttonColor.opacity(0.3), lineWidth: 1)
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
    ))
}
