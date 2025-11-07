//
//  MistakesReviewNavigationView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct MistakesReviewNavigationView: View {
    @State private var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    
    private var mistakesResultBinding: Binding<Bool> {
        Binding(
            get: {
                if case .completed(.mistakesFinished) = viewModel.state { return true }
                return false
            },
            set: { newValue in
                if !newValue {
                    viewModel.restartQuiz()
                }
            }
        )
    }
    
    init(viewModel: QuizViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        Group {
                switch viewModel.state {
                case .active(.loading):
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("mistakes.loading".localized)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .active(.mistakesReview):
                    MistakesReviewView(viewModel: viewModel)
                        .navigationDestination(isPresented: mistakesResultBinding) {
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
                            }
                        }
                    
                case .completed(.mistakesFinished):
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
                    }
                    
                case .idle:
                    // User stopped the mistakes review, go back
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("mistakes.stopped".localized)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button("mistakes.back".localized) {
                            dismiss()
                        }
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                default:
                    VStack(spacing: 20) {
                        Text("mistakes.error".localized)
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Button("mistakes.back".localized) {
                            dismiss()
                        }
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString(for: "mistakes.reviewTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                        }
                    }
                }
            }
        }
    }


#Preview {
    let viewModel = QuizViewModel(quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository()), statsManager: StatsManager(), settingsManager: SettingsManager())
    MistakesReviewNavigationView(viewModel: viewModel)
}
