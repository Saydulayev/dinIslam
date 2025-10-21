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
    
    init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(LocalizationManager.shared.localizedString(for: "mistakes.loading"))
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .mistakesReview:
                    MistakesReviewView(viewModel: viewModel)
                        .navigationDestination(
                            isPresented: Binding(
                                get: { viewModel.state == .mistakesFinished },
                                set: { isPresented in
                                    if !isPresented {
                                        viewModel.restartQuiz()
                                    }
                                }
                            )
                        ) {
                            MistakesResultView(viewModel: viewModel)
                        }
                    
                case .mistakesFinished:
                    MistakesResultView(viewModel: viewModel)
                    
                default:
                    VStack(spacing: 20) {
                        Text(LocalizationManager.shared.localizedString(for: "mistakes.error"))
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Button(LocalizationManager.shared.localizedString(for: "mistakes.back")) {
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
}

#Preview {
    let viewModel = QuizViewModel(quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository()), statsManager: StatsManager(), settingsManager: SettingsManager())
    MistakesReviewNavigationView(viewModel: viewModel)
}
