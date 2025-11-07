//
//  ResultView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI
import UserNotifications

struct ResultView: View {
    let result: QuizResult
    let newAchievements: [Achievement]
    let onPlayAgain: () -> Void
    let onBackToStart: () -> Void
    let onAchievementsCleared: () -> Void
    
    @State private var showingAchievementNotification = false
    @State private var currentAchievement: Achievement?
    @State private var achievementsCleared = false
    
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
                    Text("\(Int(result.percentage))%")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(resultColor)
                    
                    LocalizedText("result.correctAnswers")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Detailed stats
                VStack(spacing: 12) {
                    StatRow(
                        title: "result.totalQuestions".localized,
                        value: "\(result.totalQuestions)"
                    )
                    
                    StatRow(
                        title: "result.correctAnswers".localized,
                        value: "\(result.correctAnswers)"
                    )
                    
                    StatRow(
                        title: "result.timeSpent".localized,
                        value: formatTime(result.timeSpent)
                    )
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // New record badge
            if result.isNewRecord {
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
                Button(action: onPlayAgain) {
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
                
                Button(action: onBackToStart) {
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
            prepareAchievements()
            
            // Clear app badge when results are shown (iOS 17+ API)
            UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: { _ in })
        }
        .onChange(of: showingAchievementNotification) { _, newValue in
            if !newValue {
                clearAchievementsOnce()
            }
        }
    }
    
    private var resultIcon: String {
        switch result.percentage {
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
        switch result.percentage {
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
    
    private func prepareAchievements() {
        guard !newAchievements.isEmpty else { return }
        currentAchievement = newAchievements.first
        showingAchievementNotification = true
        clearAchievementsOnce()
    }
    
    private func clearAchievementsOnce() {
        guard !achievementsCleared else { return }
        achievementsCleared = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            onAchievementsCleared()
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
    let result = QuizResult(totalQuestions: 20, correctAnswers: 18, percentage: 90, timeSpent: 120)
    ResultView(
        result: result,
        newAchievements: [],
        onPlayAgain: {},
        onBackToStart: {},
        onAchievementsCleared: {}
    )
}
