//
//  ExamResultView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Observation
import SwiftUI

struct ExamResultView: View {
    let result: ExamResult
    let viewModel: ExamViewModel
    let onRetake: () -> Void
    let onBackToMenu: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    /// Новые достижения показываются по одному: первое в очереди — текущее
    @State private var pendingAchievements: [Achievement] = []
    @State private var achievementsTotal = 0
    
    /// Ошибки и пропуски уходят в повторение ошибок
    private var mistakesCount: Int {
        result.incorrectAnswers + result.skippedQuestions
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxl) {
                    // Header
                    ExamResultHeaderView(result: result)
                    
                    // Grade and score
                    ExamGradeView(result: result)
                    
                    // Statistics cards
                    ExamStatsCardsView(result: result)
                    
                    if mistakesCount > 0 {
                        ExamReviewNoteView()
                    }
                    
                    // Detailed breakdown
                    ExamBreakdownView(result: result)
                    
                    // Action buttons
                    ExamResultActionsView(
                        viewModel: viewModel,
                        onRetake: onRetake,
                        onBackToMenu: onBackToMenu
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.top, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
        .navigationTitle("exam.result.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .overlay {
            if let achievement = pendingAchievements.first {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                    
                    AchievementNotificationView(
                        achievement: achievement,
                        position: achievementsTotal - pendingAchievements.count + 1,
                        total: achievementsTotal,
                        onClose: { pendingAchievements.removeFirst() }
                    )
                    .id(achievement.id)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.8).combined(with: .opacity))
                    // Пока окно открыто, VoiceOver не уходит на экран результата под ним
                    .accessibilityAddTraits(.isModal)
                }
            }
        }
        .animation(.dsSpring(reduceMotion: reduceMotion), value: pendingAchievements.first?.id)
        .onAppear {
            // Достижения показываются один раз: при возврате на экран очередь не наполняется заново
            guard !viewModel.newAchievements.isEmpty else { return }
            pendingAchievements = viewModel.newAchievements
            achievementsTotal = pendingAchievements.count
            viewModel.newAchievements = []
        }
    }
}

// MARK: - Exam Review Note
struct ExamReviewNoteView: View {
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Image(systemName: "arrow.counterclockwise.circle.fill")
                .font(.system(size: DesignTokens.Sizes.iconMedium))
                .foregroundStyle(DesignTokens.Colors.iconOrange)
                .accessibilityHidden(true)
            
            Text("exam.result.reviewNote".localized)
                .font(DesignTokens.Typography.secondaryRegular)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding(DesignTokens.Spacing.lg)
        .glowBorder()
    }
}

// MARK: - Exam Result Header
struct ExamResultHeaderView: View {
    let result: ExamResult
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Icon
            Image(systemName: result.isPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: DesignTokens.Sizes.iconHero))
                .foregroundStyle(result.isPassed ? DesignTokens.Colors.success : DesignTokens.Colors.error)
            
            // Title
            Text(result.isPassed ? "exam.result.passed".localized : "exam.result.failed".localized)
                .font(DesignTokens.Typography.h1)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            // Score
            Text(result.percentage.displayScore)
                .font(DesignTokens.Typography.scoreMedium)
                .foregroundStyle(result.isPassed ? DesignTokens.Colors.success : DesignTokens.Colors.error)
        }
        .padding(.vertical, DesignTokens.Spacing.xl)
    }
}

// MARK: - Exam Grade View
struct ExamGradeView: View {
    let result: ExamResult
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("exam.result.grade".localized)
                .font(DesignTokens.Typography.bodyRegular)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            
            Text(result.grade.localizedName)
                .font(DesignTokens.Typography.h1)
                .foregroundStyle(gradeColor)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.md)
                .glowBorder()
        }
    }
    
    private var gradeColor: Color {
        switch result.grade {
        case .excellent:
            return DesignTokens.Colors.success
        case .good:
            return DesignTokens.Colors.iconBlue
        case .satisfactory:
            return DesignTokens.Colors.warning
        case .unsatisfactory:
            return DesignTokens.Colors.error
        }
    }
}

// MARK: - Exam Stats Cards
struct ExamStatsCardsView: View {
    let result: ExamResult
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.lg) {
            ExamStatCard(
                title: "exam.result.answered".localized,
                value: "\(result.answeredQuestions)",
                icon: "pencil.circle.fill",
                color: DesignTokens.Colors.iconBlue
            )
            
            ExamStatCard(
                title: "exam.result.correct".localized,
                value: "\(result.correctAnswers)",
                icon: "checkmark.circle.fill",
                color: DesignTokens.Colors.success
            )
            
            ExamStatCard(
                title: "exam.result.incorrect".localized,
                value: "\(result.incorrectAnswers)",
                icon: "xmark.circle.fill",
                color: DesignTokens.Colors.error
            )
            
            ExamStatCard(
                title: "exam.result.skipped".localized,
                value: "\(result.skippedQuestions)",
                icon: "forward.fill",
                color: DesignTokens.Colors.iconOrange
            )
        }
    }
}

// MARK: - Exam Stat Card
struct ExamStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.Sizes.iconMedium))
                .foregroundStyle(color)
            
            Text(value)
                .font(DesignTokens.Typography.h1)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            Text(title)
                .font(DesignTokens.Typography.label)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.lg)
        .glowBorder()
    }
}

// MARK: - Exam Breakdown View
struct ExamBreakdownView: View {
    let result: ExamResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("exam.result.breakdown".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                ExamBreakdownRow(
                    title: "exam.result.totalQuestions".localized,
                    value: "\(result.totalQuestions)",
                    color: DesignTokens.Colors.textPrimary
                )
                
                ExamBreakdownRow(
                    title: "exam.result.passingScore".localized,
                    value: ExamResult.passingPercentage.displayScore,
                    color: DesignTokens.Colors.textPrimary
                )
                
                ExamBreakdownRow(
                    title: "exam.result.timeSpent".localized,
                    value: formatTime(result.totalTimeSpent),
                    color: DesignTokens.Colors.iconBlue
                )
                
                ExamBreakdownRow(
                    title: "exam.result.averageTime".localized,
                    value: formatTime(result.averageTimePerQuestion),
                    color: DesignTokens.Colors.success
                )
                
                ExamBreakdownRow(
                    title: "exam.result.timeExpired".localized,
                    value: "\(result.timeExpiredQuestions)",
                    color: DesignTokens.Colors.error
                )
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Exam Breakdown Row
struct ExamBreakdownRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(DesignTokens.Typography.secondaryRegular)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(DesignTokens.Typography.secondarySemibold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Exam Result Actions
struct ExamResultActionsView: View {
    let viewModel: ExamViewModel
    let onRetake: () -> Void
    let onBackToMenu: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Retake exam button
            Button(action: onRetake) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                    Text("exam.result.retake".localized)
                        .font(DesignTokens.Typography.secondarySemibold)
                }
            }
            .buttonStyle(DSButtonStyle())
            
            Button(action: onBackToMenu) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "house.fill")
                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                    LocalizedText("result.backToStart")
                        .font(DesignTokens.Typography.secondarySemibold)
                }
            }
            .buttonStyle(DSButtonStyle())
        }
    }
}

#Preview {
    let statsManager = StatsManager()
    let examStatsManager = ExamStatisticsManager()
    let profileManager = ProfileManager(
        statsManager: statsManager,
        examStatisticsManager: examStatsManager,
        achievementManager: AchievementManager(notificationManager: NotificationManager())
    )
    NavigationStack {
        ExamResultView(
            result: ExamResult(
                totalQuestions: 20,
                answeredQuestions: 18,
                skippedQuestions: 2,
                correctAnswers: 16,
                incorrectAnswers: 2,
                timeExpiredQuestions: 1,
                totalTimeSpent: 600,
                averageTimePerQuestion: 30,
                percentage: 88.9,
                configuration: .default,
                completedAt: Date()
            ),
            viewModel: ExamViewModel(
                examUseCase: ExamUseCase(
                    questionsRepository: EnhancedQuestionsRepository(),
                    examStatisticsManager: examStatsManager
                ),
                examStatisticsManager: examStatsManager,
                statisticsRecorder: DefaultQuizStatisticsRecorder(statsManager: statsManager),
                achievementChecker: DefaultQuizAchievementChecker(
                    achievementManager: AchievementManager(notificationManager: NotificationManager())
                ),
                settingsManager: SettingsManager()
            ),
            onRetake: {},
            onBackToMenu: {}
        )
    }
    .environment(\.profileManager, profileManager)
}
