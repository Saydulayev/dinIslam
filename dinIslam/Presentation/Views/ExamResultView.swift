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
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignTokens.Colors.background1,
                    DesignTokens.Colors.background2
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxl) {
                    // Header
                    ExamResultHeaderView(result: result)
                    
                    // Grade and score
                    ExamGradeView(result: result)
                    
                    // Statistics cards
                    ExamStatsCardsView(result: result)
                    
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
        .interactiveDismissDisabled(true)
        .toolbarBackground(DesignTokens.Colors.background1, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Exam Result Header
struct ExamResultHeaderView: View {
    let result: ExamResult
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Icon
            Image(systemName: result.isPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(result.isPassed ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.iconRed)
            
            // Title
            Text(result.isPassed ? "exam.result.passed".localized : "exam.result.failed".localized)
                .font(DesignTokens.Typography.h1)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            // Score
            Text("\(Int(result.percentage))%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(result.isPassed ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.iconRed)
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
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text(result.grade.localizedName)
                .font(DesignTokens.Typography.h1)
                .foregroundColor(gradeColor)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.md)
                .cardStyle(
                    cornerRadius: DesignTokens.CornerRadius.medium,
                    fillColor: gradeColor.opacity(0.18),
                    shadowRadius: 8,
                    shadowYOffset: 4,
                    highlightOpacity: 0.45
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(gradeColor, lineWidth: 1)
                )
        }
    }
    
    private var gradeColor: Color {
        switch result.grade {
        case .excellent:
            return DesignTokens.Colors.statusGreen
        case .good:
            return DesignTokens.Colors.iconBlue
        case .satisfactory:
            return DesignTokens.Colors.iconOrange
        case .unsatisfactory:
            return DesignTokens.Colors.iconRed
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
                icon: "checkmark.circle.fill",
                color: DesignTokens.Colors.iconBlue
            )
            
            ExamStatCard(
                title: "exam.result.correct".localized,
                value: "\(result.correctAnswers)",
                icon: "checkmark.circle.fill",
                color: DesignTokens.Colors.statusGreen
            )
            
            ExamStatCard(
                title: "exam.result.incorrect".localized,
                value: "\(result.incorrectAnswers)",
                icon: "xmark.circle.fill",
                color: DesignTokens.Colors.iconRed
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
                .foregroundColor(color)
            
            Text(value)
                .font(DesignTokens.Typography.h1)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(title)
                .font(DesignTokens.Typography.label)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.lg)
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.medium, highlightOpacity: 0.35)
    }
}

// MARK: - Exam Breakdown View
struct ExamBreakdownView: View {
    let result: ExamResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("exam.result.breakdown".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                ExamBreakdownRow(
                    title: "exam.result.totalQuestions".localized,
                    value: "\(result.totalQuestions)",
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
                    color: DesignTokens.Colors.statusGreen
                )
                
                ExamBreakdownRow(
                    title: "exam.result.timeExpired".localized,
                    value: "\(result.timeExpiredQuestions)",
                    color: DesignTokens.Colors.iconRed
                )
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .cardStyle(cornerRadius: DesignTokens.CornerRadius.xlarge)
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
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(DesignTokens.Typography.secondarySemibold)
                .foregroundColor(color)
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
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .cardStyle(
                    cornerRadius: DesignTokens.CornerRadius.medium,
                    fillColor: DesignTokens.Colors.iconBlue,
                    shadowRadius: 10,
                    shadowYOffset: 6,
                    highlightOpacity: 0.45
                )
            }
            
            Button(action: onBackToMenu) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "house.fill")
                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                    LocalizedText("result.backToStart")
                        .font(DesignTokens.Typography.secondarySemibold)
                }
                .foregroundColor(DesignTokens.Colors.iconBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .cardStyle(
                    cornerRadius: DesignTokens.CornerRadius.medium,
                    fillColor: DesignTokens.Colors.progressCard,
                    shadowRadius: 10,
                    shadowYOffset: 6,
                    highlightOpacity: 0.35
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 1)
                )
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
                    questionsRepository: QuestionsRepository(),
                    examStatisticsManager: examStatsManager
                ),
                examStatisticsManager: examStatsManager,
                settingsManager: SettingsManager()
            ),
            onRetake: {},
            onBackToMenu: {}
        )
    }
    .environment(\.profileManager, profileManager)
}
