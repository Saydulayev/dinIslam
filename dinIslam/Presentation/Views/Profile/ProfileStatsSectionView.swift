//
//  ProfileStatsSectionView.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import SwiftUI

struct ProfileStatsSectionView: View {
    @Bindable var manager: ProfileManager
    @Bindable var statsManager: StatsManager
    let totalQuestionsCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
            Text("profile.progress.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
                    count: 2
                ),
                spacing: DesignTokens.Spacing.md
            ) {
                // Questions Studied
                ProgressCardView(
                    icon: "questionmark.circle",
                    value: "\(manager.isSignedIn ? manager.progress.totalQuestionsAnswered : statsManager.stats.totalQuestionsStudied)",
                    label: manager.isSignedIn ? "profile.progress.questions".localized : "stats.questionsStudied.title".localized,
                    iconColor: DesignTokens.Colors.iconBlue,
                    backgroundColor: DesignTokens.Colors.iconBlue.opacity(0.2)
                )
                
                // Correct Answers
                ProgressCardView(
                    icon: "checkmark.circle",
                    value: "\(manager.isSignedIn ? manager.progress.correctAnswers : statsManager.stats.correctAnswers)",
                    label: manager.isSignedIn ? "profile.progress.correct".localized : "stats.correctAnswers.title".localized,
                    iconColor: DesignTokens.Colors.iconGreen,
                    backgroundColor: DesignTokens.Colors.iconGreen.opacity(0.2)
                )
                
                // Incorrect Answers
                ProgressCardView(
                    icon: "xmark.circle",
                    value: "\(manager.isSignedIn ? manager.progress.incorrectAnswers : statsManager.stats.incorrectAnswers)",
                    label: manager.isSignedIn ? "profile.progress.incorrect".localized : "stats.incorrectAnswers.title".localized,
                    iconColor: DesignTokens.Colors.iconRed,
                    backgroundColor: DesignTokens.Colors.iconRed.opacity(0.2)
                )
                
                // Corrected Mistakes
                ProgressCardView(
                    icon: "exclamationmark.circle",
                    value: "\(manager.isSignedIn ? manager.progress.correctedMistakes : statsManager.stats.correctedMistakes)",
                    label: manager.isSignedIn ? "profile.progress.corrected".localized : "stats.correctedMistakes.title".localized,
                    iconColor: DesignTokens.Colors.iconOrange,
                    backgroundColor: DesignTokens.Colors.iconOrange.opacity(0.2)
                )
                
                // Accuracy or Quizzes Completed (для обоих показываем одинаково)
                if manager.isSignedIn {
                    ProgressCardView(
                        icon: "chart.bar",
                        value: "\(Int(manager.progress.averageQuizScore))%",
                        label: "profile.progress.accuracy".localized,
                        iconColor: DesignTokens.Colors.iconPurple,
                        backgroundColor: DesignTokens.Colors.iconPurple.opacity(0.2)
                    )
                } else {
                    // Для неавторизованных показываем точность из statsManager
                    let accuracy = statsManager.stats.totalQuestionsStudied > 0 ?
                        Int((Double(statsManager.stats.correctAnswers) / Double(statsManager.stats.totalQuestionsStudied)) * 100) : 0
                    ProgressCardView(
                        icon: "chart.bar",
                        value: "\(accuracy)%",
                        label: "profile.progress.accuracy".localized,
                        iconColor: DesignTokens.Colors.iconPurple,
                        backgroundColor: DesignTokens.Colors.iconPurple.opacity(0.2)
                    )
                }
                
                // Streak or Quizzes Completed
                if manager.isSignedIn {
                    ProgressCardView(
                        icon: "flame",
                        value: "\(manager.progress.currentStreak)",
                        label: "profile.progress.streak".localized,
                        iconColor: DesignTokens.Colors.iconOrange,
                        backgroundColor: DesignTokens.Colors.iconOrange.opacity(0.2)
                    )
                } else {
                    ProgressCardView(
                        icon: "flame",
                        value: "\(statsManager.stats.currentStreak)",
                        label: "profile.progress.streak".localized,
                        iconColor: DesignTokens.Colors.iconOrange,
                        backgroundColor: DesignTokens.Colors.iconOrange.opacity(0.2)
                    )
                }
            }
            
            // Horizontal "Total Questions" card
            HStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "book.closed")
                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                    .foregroundColor(DesignTokens.Colors.iconPurple)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("stats.totalQuestions.title".localized)
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("\(totalQuestionsCount)")
                        .font(DesignTokens.Typography.statsValue)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                Spacer()
            }
            .padding(DesignTokens.Spacing.lg)
            .cardStyle(
                cornerRadius: DesignTokens.CornerRadius.medium,
                fillColor: DesignTokens.Colors.iconPurple.opacity(0.2),
                borderColor: DesignTokens.Colors.iconPurple.opacity(0.55),
                shadowColor: Color.black.opacity(0.22)
            )
        }
        .padding(DesignTokens.Spacing.xxl)
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }
}

