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
    }
}

