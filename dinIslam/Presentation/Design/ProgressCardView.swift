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
    
    private var resolvedBackground: Color {
        backgroundColor ?? DesignTokens.Colors.progressCard
    }
    
    private var resolvedBorder: Color {
        if let backgroundColor {
            return backgroundColor.opacity(0.55)
        }
        return DesignTokens.Colors.borderDefault
    }
    
    private var resolvedShadow: Color {
        backgroundColor == nil ? Color.black.opacity(0.28) : Color.black.opacity(0.22)
    }
    
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
                .foregroundColor(.white) // Белая иконка для лучшей видимости на градиенте
            
            Text(value)
                .font(DesignTokens.Typography.statsValue)
                .foregroundColor(.white) // Белый текст для лучшей читаемости
            
            Spacer(minLength: 0)
            
            Text(label)
                .font(DesignTokens.Typography.label)
                .foregroundColor(.white.opacity(0.9)) // Белый текст с небольшой прозрачностью
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 110, maxHeight: 110, alignment: .leading)
        .padding(DesignTokens.Sizes.progressCardPadding)
        .background(
            ZStack {
                // Градиентный фон (как у кнопок на главном экране)
                LinearGradient(
                    gradient: Gradient(colors: gradientColors(for: iconColor)),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Рамка с градиентом и свечением
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
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
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
        .shadow(
            color: gradientColors(for: iconColor).first?.opacity(0.5) ?? Color.black.opacity(0.3),
            radius: 12,
            y: 6
        )
    }
    
    // MARK: - Helper
    private func gradientColors(for color: Color) -> [Color] {
        // Определяем градиент на основе цвета иконки
        if color == DesignTokens.Colors.iconBlue {
            // Синий океанский градиент (Questions Studied)
            return [
                DesignTokens.Colors.blueGradientStart,
                DesignTokens.Colors.blueGradientEnd
            ]
        } else if color == DesignTokens.Colors.iconGreen {
            // Зеленый успешный градиент (Correct Answers)
            return [
                DesignTokens.Colors.greenGradientStart,
                DesignTokens.Colors.greenGradientEnd
            ]
        } else if color == DesignTokens.Colors.iconRed {
            // Красный предупреждение (Incorrect Answers)
            return [
                DesignTokens.Colors.redGradientStart,
                DesignTokens.Colors.redGradientEnd
            ]
        } else if color == DesignTokens.Colors.iconYellow {
            // Янтарный исправление (Corrected Mistakes)
            return [
                DesignTokens.Colors.amberGradientStart,
                DesignTokens.Colors.amberGradientEnd
            ]
        } else if color == DesignTokens.Colors.iconPurple {
            // Фиолетовый статистика (Accuracy)
            return [
                DesignTokens.Colors.purpleGradientStart,
                DesignTokens.Colors.purpleGradientEnd
            ]
        } else if color == DesignTokens.Colors.iconFlame {
            // Огненный градиент (Streak)
            return [
                DesignTokens.Colors.flameGradientStart,
                DesignTokens.Colors.flameGradientEnd
            ]
        } else if color == DesignTokens.Colors.iconOrange {
            // Оранжевый градиент (для других случаев)
            return [
                DesignTokens.Colors.examButtonGradientStart,
                DesignTokens.Colors.examButtonGradientEnd
            ]
        } else {
            // По умолчанию синий градиент
            return [
                DesignTokens.Colors.blueGradientStart,
                DesignTokens.Colors.blueGradientEnd
            ]
        }
    }
}

