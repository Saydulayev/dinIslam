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
    let isResettingProfile: Bool
    let statsRefreshTrigger: Int
    @State private var studiedCount: Int = 0
    
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
                    value: "\(studiedCount) / \(totalQuestionsCount)",
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
                    iconColor: DesignTokens.Colors.iconYellow,
                    backgroundColor: DesignTokens.Colors.iconYellow.opacity(0.2)
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
                        iconColor: DesignTokens.Colors.iconFlame,
                        backgroundColor: DesignTokens.Colors.iconFlame.opacity(0.2)
                    )
                } else {
                    ProgressCardView(
                        icon: "flame",
                        value: "\(statsManager.stats.currentStreak)",
                        label: "profile.progress.streak".localized,
                        iconColor: DesignTokens.Colors.iconFlame,
                        backgroundColor: DesignTokens.Colors.iconFlame.opacity(0.2)
                    )
                }
            }
            
            // Horizontal "Total Questions" card
            HStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "book.closed")
                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                    .foregroundColor(.white) // Белая иконка для лучшей видимости на градиенте
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("stats.totalQuestions.title".localized)
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(.white.opacity(0.9)) // Белый текст с небольшой прозрачностью
                    
                    Text("\(totalQuestionsCount)")
                        .font(DesignTokens.Typography.statsValue)
                        .foregroundColor(.white) // Белый текст для лучшей читаемости
                }
                
                Spacer()
            }
            .padding(DesignTokens.Spacing.lg)
            .background(
                ZStack {
                    // Градиентный фон (как у карточек)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Colors.purpleGradientStart,
                            DesignTokens.Colors.purpleGradientEnd
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Рамка с градиентом и свечением
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
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            .shadow(
                color: DesignTokens.Colors.purpleGradientStart.opacity(0.5),
                radius: 12,
                y: 6
            )
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
        .onAppear {
            loadProgressStats()
        }
        .onChange(of: totalQuestionsCount) { _, _ in
            loadProgressStats()
        }
        .onChange(of: isResettingProfile) { _, newValue in
            // Когда сброс завершён (isResettingProfile становится false), обновляем статистику
            if !newValue {
                loadProgressStats()
            }
        }
        .onChange(of: statsRefreshTrigger) { _, _ in
            // Обновляем статистику при изменении триггера (например, после сброса для неавторизованных)
            loadProgressStats()
        }
    }
    
    private func loadProgressStats() {
        let manager = DefaultQuestionPoolProgressManager()
        let stats = manager.getProgressStats(total: totalQuestionsCount, version: 1)
        studiedCount = stats.used
    }
}

