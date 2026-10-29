//
//  WidgetPalette.swift
//  dinIslamWidget
//
//  Цвета виджета — те же, что в приложении (DesignTokens, AppBackground).
//

import SwiftUI

enum WidgetPalette {
    /// Фон как в приложении: тёмный индиго сверху, чёрный снизу
    static let background = LinearGradient(
        colors: [Color(red: 10 / 255, green: 10 / 255, blue: 26 / 255), .black],
        startPoint: .top,
        endPoint: .bottom
    )
    /// Огонь серии — iconOrange
    static let flame = Color(red: 251 / 255, green: 146 / 255, blue: 60 / 255)
    /// Ошибки к повторению — янтарный, как кнопка повторения
    static let review = Color(red: 251 / 255, green: 191 / 255, blue: 36 / 255)
    /// Сегодня занимались — statusGreen
    static let success = Color(red: 16 / 255, green: 185 / 255, blue: 129 / 255)
}
