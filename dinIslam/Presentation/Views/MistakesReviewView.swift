//
//  MistakesReviewView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct MistakesReviewView: View {
    @State private var viewModel: QuizViewModel
    @State private var showingStopConfirm: Bool = false
    
    init(viewModel: QuizViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress and score
            VStack(spacing: 16) {
                HStack {
                    LocalizedText("mistakes.title")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    LocalizedText("mistakes.score")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("\(viewModel.currentQuestionIndex + 1) / \(viewModel.questions.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(viewModel.correctAnswers)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                
                // Progress bar
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
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
                            
                            // Category and difficulty
                            HStack {
                                Label(question.category, systemImage: "tag")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Label(question.difficulty.localizedName, systemImage: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            
                            // Mistake indicator
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(LocalizationManager.shared.localizedString(for: "mistakes.wrongAnswer"))
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Answer options
                        VStack(spacing: 12) {
                            ForEach(question.answers, id: \.id) { answer in
                                let index = question.answers.firstIndex(where: { $0.id == answer.id })!
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
                        Text(LocalizationManager.shared.localizedString(for: "mistakes.stop"))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.red.gradient, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(.ultraThinMaterial)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("mistakes.reviewTitle".localized)
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
    let viewModel = QuizViewModel(quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository()), statsManager: StatsManager(), settingsManager: SettingsManager())
    MistakesReviewView(viewModel: viewModel)
}
