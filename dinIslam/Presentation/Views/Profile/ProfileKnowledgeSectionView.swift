//
//  ProfileKnowledgeSectionView.swift
//  dinIslam
//
//  «Мои знания»: точность ответов по каждой теме и переход к викторине по теме.
//

import SwiftUI

struct ProfileKnowledgeSectionView: View {
    @Bindable var statsManager: StatsManager
    let onStartTopicQuiz: (QuestionCategory) -> Void

    private var topics: [(category: QuestionCategory, stat: TopicStat)] {
        QuestionCategory.allCases.compactMap { category in
            guard let stat = statsManager.stats.topicStats[category.rawValue], stat.totalAnswers > 0 else { return nil }
            return (category, stat)
        }
    }

    private var weakestTopic: QuestionCategory? {
        topics
            .filter { $0.stat.isWeak }
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
                        Button {
                            onStartTopicQuiz(topic.category)
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                TopicProgressRow(
                                    categoryId: topic.category.rawValue,
                                    accuracy: topic.stat.accuracy / 100,
                                    detail: topic.stat.accuracy.displayScore
                                )
                                Image(systemName: "chevron.right")
                                    .font(.system(size: DesignTokens.Sizes.iconXSmall))
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                                    .accessibilityHidden(true)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.pressable)
                        .accessibilityHint("topics.startHint".localized)
                    }
                }

                if let weakestTopic {
                    MinimalButton(
                        icon: "lightbulb",
                        title: "knowledge.advice".localized(arguments: weakestTopic.localizedName)
                    ) {
                        onStartTopicQuiz(weakestTopic)
                    }
                }

                Text("knowledge.caption".localized)
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DesignTokens.Spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
        }
    }
}
