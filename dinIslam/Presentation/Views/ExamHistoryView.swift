//
//  ExamHistoryView.swift
//  dinIslam
//
//  История экзаменов: последние результаты, новые — первыми.
//

import SwiftUI

struct ExamHistoryView: View {
    let examStatisticsManager: ExamStatisticsManager

    private var history: [ExamHistoryRecord] {
        examStatisticsManager.statistics.history
    }

    var body: some View {
        ZStack {
            AppBackground()

            if history.isEmpty {
                Text("exam.history.empty".localized)
                    .font(DesignTokens.Typography.secondaryRegular)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(DesignTokens.Spacing.xxl)
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.md) {
                        ForEach(history) { record in
                            ExamHistoryRow(record: record)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    .padding(.top, DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xxxl)
                }
            }
        }
        .navigationTitle("exam.history.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Exam History Row
struct ExamHistoryRow: View {
    let record: ExamHistoryRecord

    private var statusColor: Color {
        record.isPassed ? DesignTokens.Colors.success : DesignTokens.Colors.error
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: record.isPassed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(statusColor)
                    .accessibilityHidden(true)

                Text(record.isPassed ? "exam.history.passed".localized : "exam.history.failed".localized)
                    .font(DesignTokens.Typography.secondarySemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer()

                Text(record.percentage.displayScore)
                    .font(DesignTokens.Typography.h2)
                    .foregroundStyle(statusColor)
            }

            Text(record.date.localizedFormatted(date: .abbreviated, time: .shortened))
                .font(DesignTokens.Typography.label)
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            Text(details)
                .font(DesignTokens.Typography.label)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.lg)
        .glowBorder()
        .accessibilityElement(children: .combine)
    }

    private var details: String {
        var parts = [
            "exam.history.correct".localized(arguments: record.correctAnswers, record.totalQuestions),
            record.grade.localizedName
        ]
        if record.skippedQuestions > 0 {
            parts.append("exam.history.skipped".localized(arguments: record.skippedQuestions))
        }
        parts.append(Self.formatTime(record.timeSpent))
        return parts.joined(separator: " · ")
    }

    private static func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        ExamHistoryView(examStatisticsManager: ExamStatisticsManager())
    }
}
