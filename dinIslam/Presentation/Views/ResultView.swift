//
//  ResultView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct ResultView: View {
    @State private var viewModel: QuizViewModel
    @Binding var bestScore: Double
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingAchievementNotification = false
    @State private var currentAchievement: Achievement?
    
    init(viewModel: QuizViewModel, bestScore: Binding<Double>) {
        self.viewModel = viewModel
        self._bestScore = bestScore
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Result icon
            VStack(spacing: 16) {
                Image(systemName: resultIcon)
                    .font(.system(size: 80))
                    .foregroundStyle(resultColor.gradient)
                
                LocalizedText("result.title")
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
                    
                    LocalizedText("result.correctAnswers")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Detailed stats
                VStack(spacing: 12) {
                    StatRow(
                        title: localizationManager.localizedString(for: "result.totalQuestions"),
                        value: "\(viewModel.quizResult?.totalQuestions ?? 0)"
                    )
                    
                    StatRow(
                        title: localizationManager.localizedString(for: "result.correctAnswers"),
                        value: "\(viewModel.quizResult?.correctAnswers ?? 0)"
                    )
                    
                    StatRow(
                        title: localizationManager.localizedString(for: "result.timeSpent"),
                        value: formatTime(viewModel.quizResult?.timeSpent ?? 0)
                    )
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // New record badge
            if let result = viewModel.quizResult, result.isNewRecord {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    LocalizedText("result.newRecord")
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                }
                .padding()
                .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: {
                    updateBestScore()
                    viewModel.restartQuiz()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        LocalizedText("result.playAgain")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 16))
                }
                
                Button(action: {
                    updateBestScore()
                    // Navigate back to start
                    viewModel.restartQuiz()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                        LocalizedText("result.backToStart")
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
        .overlay(
            // Achievement Notification Overlay
            Group {
                if showingAchievementNotification, let achievement = currentAchievement {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        AchievementNotificationView(
                            achievement: achievement,
                            isPresented: $showingAchievementNotification
                        )
                    }
                }
            }
        )
        .onAppear {
            checkForNewAchievements()
            updateBestScore()
        }
    }
    
    private var resultIcon: String {
        guard let percentage = viewModel.quizResult?.percentage else { return "questionmark.circle" }
        
        switch percentage {
        case 80...:
            return "trophy.fill"
        case 60..<80:
            return "star.fill"
        case 40..<60:
            return "checkmark.circle.fill"
        default:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var resultColor: Color {
        guard let percentage = viewModel.quizResult?.percentage else { return .gray }
        
        switch percentage {
        case 80...:
            return .yellow
        case 60..<80:
            return .green
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
    
    private func updateBestScore() {
        if let percentage = viewModel.quizResult?.percentage,
           percentage > bestScore {
            bestScore = percentage
        }
    }
    
    private func checkForNewAchievements() {
        let newAchievements = viewModel.newAchievements
        
        if !newAchievements.isEmpty {
            // Show the first new achievement
            currentAchievement = newAchievements.first
            showingAchievementNotification = true
            
            // Clear the achievement from the view model after showing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                viewModel.clearNewAchievements()
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    let viewModel = QuizViewModel(quizUseCase: QuizUseCase(questionsRepository: QuestionsRepository()), statsManager: StatsManager(), settingsManager: SettingsManager())
    ResultView(viewModel: viewModel, bestScore: .constant(85.0))
}
