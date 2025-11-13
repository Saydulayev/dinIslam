//
//  DesignTokens.swift
//  dinIslam
//
//  Created by GPT-5 Codex on 13.11.25.
//

import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design Tokens
struct DesignTokens {
    
    // MARK: - Colors
    struct Colors {
        // Background colors
        static let background1 = Color(hex: "#000000")
        static let background2 = Color(hex: "#000000")
        static let cardBackground = Color(hex: "#0A0A0A")
        static let progressCard = Color(hex: "#0A0A0A")
        static let hoverBackground = Color(hex: "#0A0A0A")
        
        // Text colors
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "#9CA3AF")
        static let textTertiary = Color(hex: "#6B7280")
        
        // Icon colors
        static let iconBlue = Color(hex: "#60A5FA")
        static let iconGreen = Color(hex: "#34D399")
        static let iconRed = Color(hex: "#F87171")
        static let iconOrange = Color(hex: "#FB923C")
        static let iconPurple = Color(hex: "#A78BFA")
        
        // Status colors
        static let statusGreen = Color(hex: "#10B981")
        
        // Borders
        static let borderSubtle = Color.white.opacity(0.05)
        static let borderLight = Color.white.opacity(0.10)
        static let borderDefault = Color(hex: "#2B2B2B")
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let card = Color.black.opacity(0.3)
        static let cardRadius: CGFloat = 8
        static let cardY: CGFloat = 2
        
        static let progress = Color.black.opacity(0.4)
        static let progressRadius: CGFloat = 4
    }
    
    // MARK: - Typography
    struct Typography {
        // Headers
        static let h1 = Font.system(size: 20, weight: .semibold)
        static let h2 = Font.system(size: 18, weight: .semibold)
        
        // Body text
        static let bodyRegular = Font.system(size: 16, weight: .regular)
        
        // Secondary text
        static let secondaryRegular = Font.system(size: 14, weight: .regular)
        static let secondarySemibold = Font.system(size: 14, weight: .semibold)
        
        // Labels
        static let label = Font.system(size: 12, weight: .regular)
        
        // Stats value
        static let statsValue = Font.system(size: 16, weight: .regular)
    }
    
    // MARK: - Sizes
    struct Sizes {
        // Avatar
        static let avatarSize: CGFloat = 112
        static let avatarBorderWidth: CGFloat = 4
        
        // Edit button on avatar
        static let editButtonSize: CGFloat = 40
        static let editIconSize: CGFloat = 16
        
        // Icons
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 20
        static let iconLarge: CGFloat = 24
        
        // Buttons
        static let buttonHeight: CGFloat = 40
        static let buttonPaddingHorizontal: CGFloat = 20
        static let buttonPaddingVertical: CGFloat = 8
        
        // Action buttons
        static let actionButtonPaddingHorizontal: CGFloat = 20
        static let actionButtonPaddingVertical: CGFloat = 12
        
        // Progress cards
        static let progressCardPadding: CGFloat = 20
        static let progressCardBorderWidth: CGFloat = 1
        
        // Max width
        static let maxContainerWidth: CGFloat = 448
    }
}

