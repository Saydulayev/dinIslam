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
            
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxxl) {
                    Spacer()
                        .frame(height: DesignTokens.Spacing.xxl)
                    
                    // Result icon
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Image(systemName: resultIcon)
                            .font(.system(size: 80))
                            .foregroundStyle(resultColor)
                        
                        LocalizedText("result.title")
                            .font(DesignTokens.Typography.h1)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }
                    
                    // Score details card
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        // Main score
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            Text("\(Int(result.percentage))%")
                                .font(.system(size: 60, weight: .bold, design: .rounded))
                                .foregroundStyle(resultColor)
                            
                            LocalizedText("result.correctAnswers")
                                .font(DesignTokens.Typography.bodyRegular)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                        
                        Divider()
                            .background(DesignTokens.Colors.borderSubtle)
                        
                        // Detailed stats
                        VStack(spacing: DesignTokens.Spacing.md) {
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
                    }
                    .padding(DesignTokens.Spacing.xxl)
                    .background(
                        // Прозрачная рамка с фиолетовым свечением (как на главном экране)
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
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
                    
                    // Result feedback badge
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: feedbackIcon)
                            .font(.system(size: DesignTokens.Sizes.iconMedium))
                            .foregroundColor(feedbackColor)
                        LocalizedText(resultFeedbackMessage)
                            .font(DesignTokens.Typography.secondarySemibold)
                            .foregroundColor(feedbackColor)
                    }
                    .padding(DesignTokens.Spacing.lg)
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
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    
                    Spacer()
                        .frame(height: DesignTokens.Spacing.xxl)
                    
                    // Action buttons
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Button(action: onPlayAgain) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                                LocalizedText("result.playAgain")
                                    .font(DesignTokens.Typography.secondarySemibold)
                            }
                            .foregroundColor(DesignTokens.Colors.iconBlue)
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
                        }
                        
                        Button(action: onBackToStart) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "house.fill")
                                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                                LocalizedText("result.backToStart")
                                    .font(DesignTokens.Typography.secondarySemibold)
                            }
                            .foregroundColor(DesignTokens.Colors.iconBlue)
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
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    
                    Spacer()
                        .frame(height: DesignTokens.Spacing.xxl)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
            return DesignTokens.Colors.iconOrange
        case 60..<80:
            return DesignTokens.Colors.statusGreen
        case 40..<60:
            return DesignTokens.Colors.iconOrange
        default:
            return DesignTokens.Colors.iconRed
        }
    }
    
    private var resultFeedbackMessage: String {
        switch result.percentage {
        case 90...:
            return "result.feedback.excellent"
        case 80..<90:
            return "result.feedback.great"
        case 70..<80:
            return "result.feedback.good"
        case 60..<70:
            return "result.feedback.notBad"
        case 50..<60:
            return "result.feedback.average"
        case 40..<50:
            return "result.feedback.needImprovement"
        default:
            return "result.feedback.keepPracticing"
        }
    }
    
    private var feedbackIcon: String {
        switch result.percentage {
        case 90...:
            return "star.fill"
        case 80..<90:
            return "star.fill"
        case 70..<80:
            return "checkmark.circle.fill"
        case 60..<70:
            return "checkmark.circle.fill"
        case 50..<60:
            return "exclamationmark.circle.fill"
        case 40..<50:
            return "exclamationmark.triangle.fill"
        default:
            return "book.fill"
        }
    }
    
    private var feedbackColor: Color {
        switch result.percentage {
        case 90...:
            return DesignTokens.Colors.iconOrange
        case 80..<90:
            return DesignTokens.Colors.iconOrange
        case 70..<80:
            return DesignTokens.Colors.statusGreen
        case 60..<70:
            return DesignTokens.Colors.statusGreen
        case 50..<60:
            return DesignTokens.Colors.iconOrange
        case 40..<50:
            return DesignTokens.Colors.iconOrange
        default:
            return DesignTokens.Colors.iconRed
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
        Task { @MainActor [onAchievementsCleared] in
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
                .font(DesignTokens.Typography.secondaryRegular)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(DesignTokens.Typography.secondarySemibold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
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
