import SwiftUI

// MARK: - Liquid Glass Modifier
struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    
    init(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        borderColor: Color = Color.white.opacity(0.2),
        borderWidth: CGFloat = 1
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Material фон для liquid glass эффекта
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Градиентная обводка для эффекта стекла
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    borderColor.opacity(0.6),
                                    borderColor.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: borderWidth
                        )
                }
            }
    }
}

extension View {
    func liquidGlass(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        borderColor: Color = Color.white.opacity(0.2),
        borderWidth: CGFloat = 1
    ) -> some View {
        modifier(
            LiquidGlassModifier(
                cornerRadius: cornerRadius,
                borderColor: borderColor,
                borderWidth: borderWidth
            )
        )
    }
}

struct CardStyleModifier: ViewModifier {
    let cornerRadius: CGFloat
    let fillColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat

    init(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        fillColor: Color = DesignTokens.Colors.cardBackground,
        borderColor: Color = DesignTokens.Colors.borderDefault,
        borderWidth: CGFloat = 1,
        shadowColor: Color = Color.black.opacity(0.28),
        shadowRadius: CGFloat = 6,
        shadowYOffset: CGFloat = 3
    ) {
        self.cornerRadius = cornerRadius
        self.fillColor = fillColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowYOffset = shadowYOffset
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                y: shadowYOffset
            )
    }
}

extension View {
    func cardStyle(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        fillColor: Color = DesignTokens.Colors.cardBackground,
        borderColor: Color = DesignTokens.Colors.borderDefault,
        borderWidth: CGFloat = 1,
        shadowColor: Color = Color.black.opacity(0.28),
        shadowRadius: CGFloat = 6,
        shadowYOffset: CGFloat = 3
    ) -> some View {
        modifier(
            CardStyleModifier(
                cornerRadius: cornerRadius,
                fillColor: fillColor,
                borderColor: borderColor,
                borderWidth: borderWidth,
                shadowColor: shadowColor,
                shadowRadius: shadowRadius,
                shadowYOffset: shadowYOffset
            )
        )
    }
}
