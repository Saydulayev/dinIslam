//
//  MinimalButton.swift
//  dinIslam
//
//  Created by GPT-5 Codex on 13.11.25.
//

import SwiftUI

struct MinimalButton: View {
    let icon: String
    let title: String
    let foregroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.Sizes.iconSmall))
                
                Text(title)
                    .font(DesignTokens.Typography.secondaryRegular)
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .fill(DesignTokens.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 1)
                    )
            )
        }
    }
}

