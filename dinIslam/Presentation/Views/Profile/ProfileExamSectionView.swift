//
//  ProfileExamSectionView.swift
//  dinIslam
//
//  Итоги экзаменов в профиле и переход к истории.
//

import SwiftUI

struct ProfileExamSectionView: View {
    let statistics: ExamStatistics
    let onShowHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("profile.exams.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            VStack(spacing: DesignTokens.Spacing.md) {
                row(
                    title: "profile.exams.passed".localized,
                    value: "profile.exams.passedValue".localized(
                        arguments: statistics.examsPassed, statistics.totalExamsCompleted
                    ),
                    color: DesignTokens.Colors.iconGreen
                )

                row(
                    title: "profile.exams.bestScore".localized,
                    value: statistics.bestScore.displayScore,
                    color: DesignTokens.Colors.iconBlue
                )

                row(
                    title: "profile.exams.accuracy".localized,
                    value: statistics.averageScore.displayScore,
                    color: DesignTokens.Colors.iconPurple
                )

                MinimalButton(
                    icon: "list.bullet.rectangle",
                    title: "profile.exams.history".localized,
                    action: onShowHistory
                )
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }

    private func row(title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(DesignTokens.Typography.secondaryRegular)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignTokens.Typography.bodyRegular)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}
