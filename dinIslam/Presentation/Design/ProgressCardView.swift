//
//  ProgressCardView.swift
//  dinIslam
//
//  Created by GPT-5 Codex on 13.11.25.
//

import SwiftUI

struct ProgressCardView: View {
    let icon: String
    let value: String
    let label: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.Sizes.iconMedium))
                .foregroundColor(iconColor)
            
            Text(value)
                .font(DesignTokens.Typography.statsValue)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer(minLength: 0)
            
            Text(label)
                .font(DesignTokens.Typography.label)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 110, maxHeight: 110, alignment: .leading)
        .padding(DesignTokens.Sizes.progressCardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .fill(DesignTokens.Colors.progressCard)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                        .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 1)
                )
        )
        .shadow(
            color: DesignTokens.Shadows.progress,
            radius: DesignTokens.Shadows.progressRadius,
            y: 2
        )
    }
}

