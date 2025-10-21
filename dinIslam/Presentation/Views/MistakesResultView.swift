//
//  MistakesResultView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct MistakesResultView: View {
    @State private var viewModel: QuizViewModel
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: QuizViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Result icon
            VStack(spacing: 16) {
                Image(systemName: resultIcon)
                    .font(.system(size: 80))
                    .foregroundStyle(resultColor.gradient)
                
                LocalizedText("mistakes.result.title")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
            // Score details
            VStack(spacing: 20) {
                // Main score
                VStack(spacing: 8) {
                    Text("\(Int(viewModel.quizResult?.percentage ?? 0))%")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(resultColor)
                    
                    LocalizedText("mistakes.result.correctAnswers")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Detailed stats
                VStack(spacing: 12) {
                    StatRow(
                        title: localizationManager.localizedString(for: "mistakes.result.totalQuestions"),
                        value: "\(viewModel.quizResult?.totalQuestions ?? 0)"
                    )
                    
                    StatRow(
                        title: localizationManager.localizedString(for: "mistakes.result.correctAnswers"),
                        value: "\(viewModel.quizResult?.correctAnswers ?? 0)"
                    )
                    
                    StatRow(
                        title: localizationManager.localizedString(for: "mistakes.result.timeSpent"),
                        value: formatTime(viewModel.quizResult?.timeSpent ?? 0)
                    )
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // Improvement badge
            if let result = viewModel.quizResult, result.percentage >= 70 {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                    LocalizedText("mistakes.result.improvement")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding()
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            } else if let result = viewModel.quizResult, result.percentage < 50 {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.orange)
                    LocalizedText("mistakes.result.needMorePractice")
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: {
                    viewModel.restartQuiz()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        LocalizedText("mistakes.result.repeatAgain")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.red.gradient, in: RoundedRectangle(cornerRadius: 16))
                }
                
                Button(action: {
                    // Navigate back to start
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        LocalizedText("mistakes.result.backToStart")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
    
    private var resultIcon: String {
        guard let percentage = viewModel.quizResult?.percentage else { return "questionmark.circle" }
        
        switch percentage {
        case 80...:
            return "checkmark.circle.fill"
        case 60..<80:
            return "arrow.up.circle.fill"
        case 40..<60:
            return "arrow.down.circle.fill"
        default:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var resultColor: Color {
        guard let percentage = viewModel.quizResult?.percentage else { return .gray }
        
        switch percentage {
        case 80...:
            return .green
        case 60..<80:
            return .blue
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}

#Preview {
    let viewModel = QuizViewModel(quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository()), statsManager: StatsManager(), settingsManager: SettingsManager())
    MistakesResultView(viewModel: viewModel)
}
