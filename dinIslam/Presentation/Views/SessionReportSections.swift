//
//  SessionReportSections.swift
//  dinIslam
//
//  Итоги сессии на экранах результата: серия дней, темы, ошибки и повторение.
//

import SwiftUI

struct SessionReportSections: View {
    let report: SessionReport
    var onRepeatMistakes: (([String]) -> Void)? = nil

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            streakBanner

            if report.hasTopicBreakdown {
                topicsCard
            }

            if let review = report.review {
                ReviewSummaryCard(summary: review)
            } else if !report.mistakeIds.isEmpty {
                mistakesCard
            }
        }
    }

    // MARK: - Streak

    @ViewBuilder
    private var streakBanner: some View {
        if report.kind == .daily || report.dayStreak > 1 {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "flame.fill")
                    .font(.system(size: DesignTokens.Sizes.iconLarge))
                    .foregroundStyle(DesignTokens.Colors.iconOrange)

                VStack(alignment: .leading, spacing: 2) {
                    if report.kind == .daily {
                        Text("result.dailyGoal.completed".localized)
                            .font(DesignTokens.Typography.secondarySemibold)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }
                    Text(streakText)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                Spacer()
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity)
            .glowBorder()
        }
    }

    private var streakText: String {
        "result.streak".localized(arguments: report.dayStreak, "streak.days".localized(count: report.dayStreak))
    }

    // MARK: - Topics

    private var topicsCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("result.topics.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            ForEach(report.topicResults) { topic in
                TopicProgressRow(
                    categoryId: topic.categoryId,
                    accuracy: topic.accuracy,
                    detail: "\(topic.correct)/\(topic.total)"
                )
            }

            if let weakest = weakTopicsText {
                Label(weakest, systemImage: "arrow.uturn.backward.circle")
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }

    /// Темы, где ответов меньше 70% правильных
    private var weakTopicsText: String? {
        let weak = report.topicResults
            .filter { $0.categoryId != QuestionCategory.generalId && $0.accuracy < 0.7 }
            .map { QuestionCategory.displayName(for: $0.categoryId) }
        guard !weak.isEmpty else { return nil }
        return "result.topics.weak".localized(arguments: weak.joined(separator: ", "))
    }

    // MARK: - Mistakes

    private var mistakesCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                    .foregroundStyle(DesignTokens.Colors.iconOrange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("result.mistakes.added".localized(count: report.mistakeIds.count, arguments: report.mistakeIds.count))
                        .font(DesignTokens.Typography.secondarySemibold)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text("result.mistakes.hint".localized)
                        .font(DesignTokens.Typography.label)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            if let onRepeatMistakes {
                GradientActionButton(
                    icon: "exclamationmark.arrow.circlepath",
                    title: "result.mistakes.repeatNow".localized,
                    gradient: [DesignTokens.Colors.amberGradientStart, DesignTokens.Colors.amberGradientEnd]
                ) {
                    onRepeatMistakes(report.mistakeIds)
                }
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }
}

// MARK: - Review Summary

struct ReviewSummaryCard: View {
    let summary: ReviewSessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("review.summary.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if summary.graduated > 0 {
                row(icon: "checkmark.seal.fill", color: DesignTokens.Colors.success,
                    title: "review.summary.graduated".localized, value: summary.graduated)
            }
            if summary.advanced > 0 {
                row(icon: "calendar.badge.clock", color: DesignTokens.Colors.iconBlueLight,
                    title: "review.summary.advanced".localized, value: summary.advanced)
            }
            if summary.reset > 0 {
                row(icon: "arrow.counterclockwise", color: DesignTokens.Colors.iconOrange,
                    title: "review.summary.reset".localized, value: summary.reset)
            }
            if summary.notDue > 0 {
                row(icon: "clock", color: DesignTokens.Colors.textSecondary,
                    title: "review.summary.notDue".localized, value: summary.notDue)
            }

            Divider().overlay(DesignTokens.Colors.borderSubtle)

            if summary.remaining == 0 {
                Text("review.summary.allLearned".localized)
                    .font(DesignTokens.Typography.secondarySemibold)
                    .foregroundStyle(DesignTokens.Colors.success)
            } else if let next = ReviewDateText.nextReview(summary.nextDueDate) {
                Text(next)
                    .font(DesignTokens.Typography.secondaryRegular)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Text("review.summary.howItWorks".localized)
                .font(DesignTokens.Typography.label)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.Spacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }

    private func row(icon: String, color: Color, title: String, value: Int) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 22)
            Text(title)
                .font(DesignTokens.Typography.secondaryRegular)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            Spacer()
            Text("\(value)")
                .font(DesignTokens.Typography.secondarySemibold)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
    }
}

// MARK: - Dates

enum ReviewDateText {
    /// «Следующее повторение: завтра / через N дней»
    static func nextReview(_ date: Date?, now: Date = Date(), calendar: Calendar = .current) -> String? {
        guard let date else { return nil }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: date)
        ).day ?? 0

        let when: String
        switch days {
        case ...0: when = "review.when.today".localized
        case 1: when = "review.when.tomorrow".localized
        default: when = "review.when.inDays".localized(count: days, arguments: days)
        }
        return "review.next".localized(arguments: when)
    }
}

#Preview {
    ScrollView {
        SessionReportSections(
            report: SessionReport(
                kind: .daily,
                topicResults: [
                    .init(categoryId: "prophets", correct: 2, total: 3),
                    .init(categoryId: "fiqh", correct: 2, total: 2)
                ],
                mistakeIds: ["q1"],
                dayStreak: 4,
                review: nil
            ),
            onRepeatMistakes: { _ in }
        )
        .padding()
    }
    .background(Color.black)
}
