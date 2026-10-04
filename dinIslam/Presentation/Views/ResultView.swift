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
    var report: SessionReport? = nil
    var onRepeatMistakes: (([String]) -> Void)? = nil
    
    /// Новые достижения показываются по одному: первое в очереди — текущее
    @State private var pendingAchievements: [Achievement] = []
    @State private var achievementsTotal = 0
    @State private var achievementsCleared = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxxl) {
                    Spacer()
                        .frame(height: DesignTokens.Spacing.xxl)
                    
                    // Result icon
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Image(systemName: resultIcon)
                            .font(.system(size: DesignTokens.Sizes.iconHero))
                            .foregroundStyle(resultColor)
                        
                        LocalizedText("result.title")
                            .font(DesignTokens.Typography.h1)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }
                    
                    // Score details card
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        // Main score
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            Text(result.percentage.displayScore)
                                .font(DesignTokens.Typography.scoreLarge)
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
                    .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
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
                    .glowBorder()
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    
                    if let report {
                        SessionReportSections(report: report, onRepeatMistakes: onRepeatMistakes)
                            .padding(.horizontal, DesignTokens.Spacing.xxl)
                    }
                    
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
                            .glowBorder()
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
                            .glowBorder()
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
        .toolbarColorScheme(.dark, for: .navigationBar)
        .overlay(
            // Achievement Notification Overlay
            Group {
                if let achievement = pendingAchievements.first {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .accessibilityHidden(true)
                        
                        AchievementNotificationView(
                            achievement: achievement,
                            position: achievementsTotal - pendingAchievements.count + 1,
                            total: achievementsTotal,
                            onClose: showNextAchievement
                        )
                        .id(achievement.id)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        // Пока окно открыто, VoiceOver не уходит на экран результата под ним
                        .accessibilityAddTraits(.isModal)
                    }
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: pendingAchievements.first?.id)
        )
        .onAppear {
            prepareAchievements()
            
            // Clear app badge when results are shown (iOS 17+ API)
            UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: { _ in })
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
            return "time.seconds.short".localized(arguments: seconds)
        }
    }
    
    private func prepareAchievements() {
        guard !newAchievements.isEmpty, pendingAchievements.isEmpty else { return }
        pendingAchievements = newAchievements
        achievementsTotal = newAchievements.count
        clearAchievementsOnce()
    }
    
    private func showNextAchievement() {
        guard !pendingAchievements.isEmpty else { return }
        pendingAchievements.removeFirst()
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
