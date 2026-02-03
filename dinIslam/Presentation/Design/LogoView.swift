//
//  LogoView.swift
//  dinIslam
//
//  Created by Senior Developer
//

import SwiftUI

/// Современный компонент логотипа
/// Использует iOS 17+ API и оптимизирован для производительности
struct LogoView: View {
    // MARK: - Properties
    let glowIntensity: Double
    
    // MARK: - Constants
    private let logoSize: CGFloat = 100
    private let containerSize: CGFloat = 140
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Контейнер с рамкой
            containerFrame
            
            // Логотип с эффектами
            logoContent
        }
        .drawingGroup() // Оптимизация: группировка слоев для лучшей производительности
    }
    
    // MARK: - Container Frame
    private var containerFrame: some View {
        RoundedRectangle(cornerRadius: 24)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignTokens.Colors.iconPurpleLight.opacity(0.5 * glowIntensity),
                        DesignTokens.Colors.iconPurpleLight.opacity(0.2 * glowIntensity)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .frame(width: containerSize, height: containerSize)
            .shadow(
                color: DesignTokens.Colors.iconPurpleLight.opacity(0.3 * glowIntensity),
                radius: 12,
                x: 0,
                y: 0
            )
    }
    
    // MARK: - Logo Content
    private var logoContent: some View {
        // Основное изображение логотипа
        logoImage
    }
    
    // MARK: - Logo Image
    private var logoImage: some View {
        Image("image")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: logoSize, height: logoSize)
            .clipShape(Circle())
            .shadow(
                color: DesignTokens.Colors.iconBlueLight.opacity(0.5 * glowIntensity),
                radius: 20,
                x: 0,
                y: 10
            )
            .shadow(
                color: DesignTokens.Colors.iconPurpleLight.opacity(0.4 * glowIntensity),
                radius: 30,
                x: 0,
                y: 0
            )
    }
    
}

// MARK: - Preview
#Preview {
    ZStack {
        // Темный фон для превью
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#0a0a1a"),
                Color(hex: "#000000")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        LogoView(glowIntensity: 1.0)
    }
}

