//
//  TopicPickerRow.swift
//  dinIslam
//
//  Тема на экране выбора: изучено вопросов, точность, пометка слабой темы.
//

import SwiftUI

struct TopicPickerRow: View {
    let topic: TopicBankProgress
    let stat: TopicStat?
    let action: () -> Void

    private var isWeak: Bool {
        stat?.isWeak ?? false
    }

    private var details: String {
        var parts = ["topics.studied".localized(arguments: topic.progress.studied, topic.progress.total)]
        if let stat, stat.totalAnswers > 0 {
            parts.append("topics.accuracy".localized(arguments: stat.accuracy.displayScore))
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: topic.category.icon)
                        .font(.system(size: DesignTokens.Sizes.iconSmall))
                        .foregroundStyle(DesignTokens.Colors.iconPurpleLight)
                        .frame(width: 22)
                        .accessibilityHidden(true)

                    Text(topic.category.localizedName)
                        .font(DesignTokens.Typography.secondarySemibold)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: DesignTokens.Spacing.sm)

                    if isWeak {
                        Text("topics.weak".localized)
                            .font(DesignTokens.Typography.label)
                            .foregroundStyle(DesignTokens.Colors.warning)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(DesignTokens.Colors.warning.opacity(0.15)))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: DesignTokens.Sizes.iconXSmall))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .accessibilityHidden(true)
                }

                ProgressView(value: topic.studiedFraction)
                    .tint(DesignTokens.Colors.iconPurpleLight)
                    .accessibilityHidden(true)

                Text(details)
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.lg)
            .glowBorder()
            .contentShape(.rect)
        }
        .buttonStyle(.pressable)
        .accessibilityHint("topics.startHint".localized)
    }
}
