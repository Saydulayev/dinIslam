//
//  LearningComponents.swift
//  dinIslam
//
//  Общие элементы учебного цикла: кнопки действий, строки тем.
//

import SwiftUI

// MARK: - Glow Border

/// Прозрачная рамка с фиолетовым свечением (как на главном экране).
/// Отдельной View — для мест, где рамка стоит в overlay или внутри ZStack
struct GlowBorder: View {
    var cornerRadius: CGFloat = DesignTokens.CornerRadius.medium
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
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
}

extension View {
    /// Прозрачная рамка с фиолетовым свечением под содержимым
    func glowBorder(cornerRadius: CGFloat = DesignTokens.CornerRadius.medium) -> some View {
        background(GlowBorder(cornerRadius: cornerRadius))
    }
}

// MARK: - Gradient Action Button

struct GradientActionButton: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil
    let gradient: [Color]
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignTokens.Typography.secondarySemibold)
                        .foregroundStyle(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(DesignTokens.Typography.label)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                Spacer()

                if let badge {
                    Text(badge)
                        .font(DesignTokens.Typography.secondarySemibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.white.opacity(0.2)))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: DesignTokens.Sizes.iconSmall))
                    .foregroundStyle(.white)
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .glowBorder()
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            .shadow(color: (gradient.first ?? .clear).opacity(0.5), radius: 12, y: 6)
        }
        .buttonStyle(.pressable)
        .disabled(isLoading)
    }
}

// MARK: - Topic Row

/// Тема с полосой прогресса: используется в итогах сессии и в разделе «Мои знания»
struct TopicProgressRow: View {
    let categoryId: String
    let accuracy: Double
    let detail: String

    private var color: Color {
        switch accuracy {
        case 0.8...: return DesignTokens.Colors.success
        case 0.5..<0.8: return DesignTokens.Colors.warning
        default: return DesignTokens.Colors.error
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: QuestionCategory.icon(for: categoryId))
                    .font(.system(size: DesignTokens.Sizes.iconSmall))
                    .foregroundStyle(DesignTokens.Colors.iconPurpleLight)
                    .frame(width: 22)
                Text(QuestionCategory.displayName(for: categoryId))
                    .font(DesignTokens.Typography.secondaryRegular)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                Text(detail)
                    .font(DesignTokens.Typography.secondarySemibold)
                    .foregroundStyle(color)
            }
            ProgressView(value: min(max(accuracy, 0), 1))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 16) {
        TopicProgressRow(categoryId: "prophets", accuracy: 0.75, detail: "3/4")
        GradientActionButton(
            icon: "sun.max.fill",
            title: "Ежедневная практика",
            subtitle: "5 вопросов · ~2 минуты",
            gradient: [DesignTokens.Colors.greenGradientStart, DesignTokens.Colors.greenGradientEnd]
        ) {}
    }
    .padding()
    .background(Color.black)
}
