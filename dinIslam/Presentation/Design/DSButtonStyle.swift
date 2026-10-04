//
//  DSButtonStyle.swift
//  dinIslam
//

import SwiftUI

/// Роль кнопки задаёт её цвет: текст у контурной кнопки и градиент у залитой
enum DSButtonRole {
    case primary
    case secondary
    case success
    case warning
    case destructive

    var tint: Color {
        switch self {
        case .primary: return DesignTokens.Colors.iconBlue
        case .secondary: return DesignTokens.Colors.textSecondary
        case .success: return DesignTokens.Colors.success
        case .warning: return DesignTokens.Colors.warning
        case .destructive: return DesignTokens.Colors.destructive
        }
    }

    var gradient: [Color] {
        switch self {
        case .primary, .secondary:
            return [DesignTokens.Colors.quizButtonGradientStart, DesignTokens.Colors.quizButtonGradientEnd]
        case .success:
            return [DesignTokens.Colors.greenGradientStart, DesignTokens.Colors.greenGradientEnd]
        case .warning:
            return [DesignTokens.Colors.examButtonGradientStart, DesignTokens.Colors.examButtonGradientEnd]
        case .destructive:
            return [DesignTokens.Colors.redGradientStart, DesignTokens.Colors.redGradientEnd]
        }
    }
}

/// Общий стиль кнопок:
/// - `outlined` — кнопка высотой 56 со светящейся рамкой и цветным текстом;
/// - `filled` — компактная кнопка-строка с градиентной заливкой (MinimalButton).
struct DSButtonStyle: ButtonStyle {
    enum Variant {
        case outlined
        case filled
    }

    var role: DSButtonRole = .primary
    var variant: Variant = .outlined

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        Group {
            switch variant {
            case .outlined:
                outlined(configuration.label)
            case .filled:
                filled(configuration.label)
            }
        }
        .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
        .contentShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
    }

    private func outlined(_ label: Configuration.Label) -> some View {
        label
            .foregroundStyle(role.tint)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .glowBorder()
    }

    private func filled(_ label: Configuration.Label) -> some View {
        let gradient = role.gradient
        return label
            .foregroundStyle(.white)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Градиентный фон кнопки с уменьшенной контрастностью
                    LinearGradient(
                        gradient: Gradient(colors: gradient.map { $0.opacity(0.6) }),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Рамка в стиле логотипа: тоньше и тусклее, чем GlowBorder
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
                color: (gradient.first ?? .clear).opacity(0.3),
                radius: 8,
                y: 4
            )
    }
}

/// Кнопка без оформления, но с откликом на нажатие — для строк и карточек вместо `.plain`
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
