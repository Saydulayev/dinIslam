//
//  AppBackground.swift
//  dinIslam
//

import SwiftUI

/// Фон всех экранов: очень тёмный градиент от индиго сверху к чёрному снизу
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#0a0a1a"), // темно-индиго сверху
                Color(hex: "#000000") // черный снизу
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
