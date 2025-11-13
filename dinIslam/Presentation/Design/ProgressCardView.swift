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
    let backgroundColor: Color?
    
    init(
        icon: String,
        value: String,
        label: String,
        iconColor: Color,
        backgroundColor: Color? = nil
    ) {
        self.icon = icon
        self.value = value
        self.label = label
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
    }
    
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
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 110, maxHeight: 110, alignment: .leading)
        .padding(DesignTokens.Sizes.progressCardPadding)
        .cardStyle(
            cornerRadius: DesignTokens.CornerRadius.large,
            fillColor: backgroundColor ?? DesignTokens.Colors.progressCard,
            highlightOpacity: backgroundColor == nil ? 0.6 : 0.4
        )
    }
}

