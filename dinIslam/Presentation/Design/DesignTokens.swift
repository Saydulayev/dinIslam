//
//  DesignTokens.swift
//  dinIslam
//
//  Created by Saydulayev on 12.01.26.
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

// MARK: - Score Formatting
extension Double {
    /// Процент (0…100) для показа: округление до целого, но неполный результат
    /// не превращается в «100%», а ненулевой — в «0%»
    var displayScore: String {
        var value = Int(rounded())
        if self > 0 && self < 100 {
            value = Swift.min(Swift.max(value, 1), 99)
        }
        return "\(value)%"
    }
}

// MARK: - Motion
extension Animation {
    /// Пружина интерфейса; при «Уменьшении движения» — короткое плавное появление без отскока
    static func dsSpring(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.6, dampingFraction: 0.8)
    }
}

// MARK: - Design Tokens
struct DesignTokens {
    
    // MARK: - Colors
    struct Colors {
        // Background colors - точные цвета из дизайна
        static let background1 = Color(hex: "#000000") // черный фон
        static let background2 = Color(hex: "#000000") // черный для градиента
        static let cardBackground = Color(hex: "#262626") // neutral-800 - карточка
        static let progressCard = Color(hex: "#262626") // neutral-800
        static let hoverBackground = Color(hex: "#171717") // neutral-900 - hover
        
        // Text colors - из дизайна
        static let textPrimary = Color.white // основной текст
        static let textSecondary = Color(hex: "#9ca3af") // gray-400 - вторичный текст
        static let textTertiary = Color(hex: "#9ca3af") // gray-400 - третичный текст
        
        // Icon colors - точные цвета из дизайна
        static let iconBlue = Color(hex: "#3b82f6") // blue-500
        static let iconBlueLight = Color(hex: "#60a5fa") // blue-400
        static let iconGreen = Color(hex: "#34D399")
        static let iconRed = Color(hex: "#F87171")
        static let iconOrange = Color(hex: "#fb923c") // orange-400
        static let iconPurple = Color(hex: "#8b5cf6") // purple-500
        static let iconPurpleLight = Color(hex: "#a78bfa") // purple-400
        
        // Yellow colors (для лампочки и исправленных ошибок)
        static let iconYellow = Color(hex: "#fbbf24") // amber-500
        static let iconYellowLight = Color(hex: "#fde68a") // amber-200
        
        // Flame/Fire color (для streak)
        static let iconFlame = Color(hex: "#ef4444") // red-500 с оранжевым оттенком
        
        // Status colors
        static let statusGreen = Color(hex: "#10B981")
        
        // Semantic colors - по смыслу, а не по оттенку
        static let success = statusGreen  // верный ответ, экзамен сдан, синхронизировано
        static let error = iconRed        // неверный ответ, экзамен не сдан, время вышло
        static let warning = iconOrange   // требует внимания: таймер, ошибка синхронизации
        static let destructive = iconRed  // разрушительные действия: сброс, выход, удаление
        
        // Borders - нейтральные цвета
        static let borderSubtle = Color(hex: "#171717").opacity(0.3) // neutral-900 с прозрачностью
        static let borderLight = Color(hex: "#171717").opacity(0.5) // neutral-900 с прозрачностью
        static let borderDefault = Color(hex: "#171717") // neutral-900
        
        // Button gradients - градиенты для кнопок
        static let quizButtonGradientStart = Color(hex: "#1e3a8a") // blue-900
        static let quizButtonGradientEnd = Color(hex: "#1e40af") // blue-800
        static let examButtonGradientStart = Color(hex: "#431407") // orange-950
        static let examButtonGradientEnd = Color(hex: "#7c2d12") // orange-900
        
        // Card gradients - тематические градиенты для карточек прогресса
        // Синий океанский (Questions Studied)
        static let blueGradientStart = Color(hex: "#1e3a8a") // blue-900
        static let blueGradientEnd = Color(hex: "#1e40af") // blue-800
        
        // Зеленый успешный (Correct Answers)
        static let greenGradientStart = Color(hex: "#14532d") // green-950
        static let greenGradientEnd = Color(hex: "#166534") // green-900
        
        // Красный предупреждение (Incorrect Answers)
        static let redGradientStart = Color(hex: "#7f1d1d") // red-900
        static let redGradientEnd = Color(hex: "#991b1b") // red-800
        
        // Янтарный исправление (Corrected Mistakes)
        static let amberGradientStart = Color(hex: "#78350f") // amber-950
        static let amberGradientEnd = Color(hex: "#92400e") // amber-900
        
        // Фиолетовый статистика (Accuracy)
        static let purpleGradientStart = Color(hex: "#581c87") // purple-900
        static let purpleGradientEnd = Color(hex: "#6b21a8") // purple-800
        
        // Огненный streak (Current Streak)
        static let flameGradientStart = Color(hex: "#7c2d12") // orange-900
        static let flameGradientEnd = Color(hex: "#dc2626") // red-600
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
        static let overlayCard: CGFloat = 20 // всплывающая карточка нового достижения
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
    // Текстовые стили масштабируются вместе с Dynamic Type.
    // В скобках — размер при стандартной настройке.
    struct Typography {
        // Headers
        static let h1 = Font.system(.title3, weight: .semibold)      // 20
        static let h2 = Font.system(.headline)                      // 17, semibold
        
        // Body text
        static let bodyRegular = Font.system(.callout)              // 16
        
        // Secondary text
        static let secondaryRegular = Font.system(.subheadline)     // 15
        static let secondarySemibold = Font.system(.subheadline, weight: .semibold)
        
        // Labels
        static let label = Font.system(.caption)                    // 12
        
        // Stats value
        static let statsValue = Font.system(.callout)               // 16
        
        // Крупные цифры и заголовки экранов результата — фиксированный размер
        static let scoreLarge = Font.system(size: 60, weight: .bold, design: .rounded)
        static let scoreMedium = Font.system(size: 48, weight: .bold, design: .rounded)
        static let displayTitle = Font.system(size: 24, weight: .bold)
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
        static let iconXSmall: CGFloat = 12     // шевроны
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 20
        static let iconLarge: CGFloat = 24
        static let iconXLarge: CGFloat = 32     // иконка во всплывающем достижении
        static let iconXXLarge: CGFloat = 50    // иконка в раскрытой карточке достижения
        static let iconDisplay: CGFloat = 56    // заглушка аватара, пауза экзамена
        static let iconHero: CGFloat = 80       // главная иконка экранов результата
        
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
    
    // MARK: - Limits (validation / input)
    struct Limits {
        /// Максимальная длина отображаемого имени (вместо «Гость»). 20 символов — достаточно для имени или никнейма.
        static let maxDisplayNameLength: Int = 20
    }
}

