//
//  MistakesReviewNavigationView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct MistakesReviewNavigationView: View {
    @Bindable var viewModel: QuizViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: QuizViewModel) {
        _viewModel = Bindable(viewModel)
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
                    
                case .completed(.mistakesFinished):
                    // Show result screen when mistakes review is finished
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
                    } else {
                        // Fallback if result is not ready yet
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("mistakes.loading".localized)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                case .idle:
                    // User stopped the mistakes review - onChange will handle dismiss
                    // This case should rarely be visible, but kept as fallback
                    EmptyView()
                    
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
            .onChange(of: viewModel.state) { _, newState in
                // Auto-dismiss when user stops the review
                if case .idle = newState {
                    dismiss()
                }
            }
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
    return MistakesReviewNavigationView(viewModel: viewModel)
}
