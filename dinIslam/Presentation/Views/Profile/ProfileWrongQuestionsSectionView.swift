//
//  ProfileWrongQuestionsSectionView.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import SwiftUI

struct ProfileWrongQuestionsSectionView: View {
    @Bindable var statsManager: StatsManager
    let onStartMistakesReview: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("stats.wrongQuestions".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("stats.wrongQuestionsCount.title".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Spacer()
                    Text("\(statsManager.stats.wrongQuestionsCount)")
                        .font(DesignTokens.Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.iconRed)
                }
                
                HStack {
                    Text("stats.reviewDueToday.title".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Spacer()
                    Text("\(statsManager.dueReviewCount)")
                        .font(DesignTokens.Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.iconOrange)
                }
                
                if statsManager.dueReviewCount == 0, let next = ReviewDateText.nextReview(statsManager.nextReviewDate) {
                    Text(next)
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Text("review.summary.howItWorks".localized)
                    .font(DesignTokens.Typography.label)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                MinimalButton(
                    icon: "exclamationmark.triangle",
                    title: "stats.repeatMistakes".localized,
                    foregroundColor: DesignTokens.Colors.iconRed
                ) {
                    onStartMistakesReview()
                }
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }
}

