//
//  ProfileKnowledgeSectionView.swift
//  dinIslam
//
//  «Мои знания»: точность ответов по каждой теме и подсказка, что повторить.
//

import SwiftUI

struct ProfileKnowledgeSectionView: View {
    @Bindable var statsManager: StatsManager

    /// Чтобы оценка темы была осмысленной, нужно несколько ответов
    private let minimumAnswersForAdvice = 5

    private var topics: [(category: QuestionCategory, stat: TopicStat)] {
        QuestionCategory.allCases.compactMap { category in
            guard let stat = statsManager.stats.topicStats[category.rawValue], stat.totalAnswers > 0 else { return nil }
            return (category, stat)
        }
    }

    private var weakestTopic: QuestionCategory? {
        topics
            .filter { $0.stat.totalAnswers >= minimumAnswersForAdvice && $0.stat.accuracy < 70 }
            .min { $0.stat.accuracy < $1.stat.accuracy }?
            .category
    }

    var body: some View {
        if !topics.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                Text("knowledge.title".localized)
                    .font(DesignTokens.Typography.h2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                VStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(topics, id: \.category) { topic in
                        TopicProgressRow(
                            categoryId: topic.category.rawValue,
                            accuracy: topic.stat.accuracy / 100,
                            detail: topic.stat.accuracy.displayScore
                        )
                    }
                }

                if let weakestTopic {
                    Label(
                        "knowledge.advice".localized(arguments: weakestTopic.localizedName),
                        systemImage: "lightbulb"
                    )
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Text("knowledge.caption".localized)
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            .padding(DesignTokens.Spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
        }
    }
}
