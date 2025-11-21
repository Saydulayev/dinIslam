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
                    .foregroundColor(.white)
                
                Text(title)
                    .font(DesignTokens.Typography.secondaryRegular)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Градиентный фон кнопки с уменьшенной контрастностью
                    LinearGradient(
                        gradient: Gradient(colors: [
                            buttonGradientStart(for: foregroundColor).opacity(0.6),
                            buttonGradientEnd(for: foregroundColor).opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Рамка в стиле логотипа с градиентом и свечением
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    DesignTokens.Colors.iconPurpleLight.opacity(0.4),
                                    DesignTokens.Colors.iconPurpleLight.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .shadow(
                            color: DesignTokens.Colors.iconPurpleLight.opacity(0.2),
                            radius: 8,
                            x: 0,
                            y: 0
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            .shadow(
                color: buttonGradientStart(for: foregroundColor).opacity(0.3),
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper
    private func buttonGradientStart(for color: Color) -> Color {
        // Определяем градиент на основе цвета иконки
        if color == DesignTokens.Colors.iconBlue {
            return DesignTokens.Colors.quizButtonGradientStart
        } else if color == DesignTokens.Colors.iconOrange {
            return DesignTokens.Colors.examButtonGradientStart
        } else if color == DesignTokens.Colors.iconRed {
            return Color(hex: "#7f1d1d") // dark red
        } else if color == DesignTokens.Colors.iconGreen {
            return Color(hex: "#14532d") // dark green
        } else {
            // По умолчанию синий градиент
            return DesignTokens.Colors.quizButtonGradientStart
        }
    }
    
    private func buttonGradientEnd(for color: Color) -> Color {
        if color == DesignTokens.Colors.iconBlue {
            return DesignTokens.Colors.quizButtonGradientEnd
        } else if color == DesignTokens.Colors.iconOrange {
            return DesignTokens.Colors.examButtonGradientEnd
        } else if color == DesignTokens.Colors.iconRed {
            return Color(hex: "#991b1b") // red-800
        } else if color == DesignTokens.Colors.iconGreen {
            return Color(hex: "#166534") // green-800
        } else {
            return DesignTokens.Colors.quizButtonGradientEnd
        }
    }
}

