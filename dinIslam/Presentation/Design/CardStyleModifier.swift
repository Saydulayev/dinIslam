import SwiftUI

struct CardStyleModifier: ViewModifier {
    let cornerRadius: CGFloat
    let fillColor: Color
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat
    let highlightOpacity: Double

    init(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.large,
        fillColor: Color = DesignTokens.Colors.cardBackground,
        shadowRadius: CGFloat = 12,
        shadowYOffset: CGFloat = 8,
        highlightOpacity: Double = 0.6
    ) {
        self.cornerRadius = cornerRadius
        self.fillColor = fillColor
        self.shadowRadius = shadowRadius
        self.shadowYOffset = shadowYOffset
        self.highlightOpacity = highlightOpacity
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(DesignTokens.Colors.borderLight.opacity(0.7), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        DesignTokens.Colors.borderSubtle.opacity(0.0),
                                        DesignTokens.Colors.borderSubtle.opacity(highlightOpacity)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: DesignTokens.Shadows.card.opacity(0.45),
                radius: shadowRadius,
                y: shadowYOffset
            )
            .shadow(
                color: DesignTokens.Colors.textPrimary.opacity(0.05),
                radius: 2,
                y: 0
            )
    }
}

extension View {
    func cardStyle(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.large,
        fillColor: Color = DesignTokens.Colors.cardBackground,
        shadowRadius: CGFloat = 12,
        shadowYOffset: CGFloat = 8,
        highlightOpacity: Double = 0.6
    ) -> some View {
        modifier(
            CardStyleModifier(
                cornerRadius: cornerRadius,
                fillColor: fillColor,
                shadowRadius: shadowRadius,
                shadowYOffset: shadowYOffset,
                highlightOpacity: highlightOpacity
            )
        )
    }
}
