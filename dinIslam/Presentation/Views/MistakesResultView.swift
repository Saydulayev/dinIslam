//
//  MistakesResultView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct MistakesResultView: View {
    let result: QuizResult
    let onRepeat: () -> Void
    let onBackToStart: () -> Void
    @Environment(\.localizationProvider) private var localizationProvider
    
    var body: some View {
        ZStack {
            // Background - очень темный градиент с оттенками индиго/фиолетового (как на главном экране)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#0a0a1a"), // темно-индиго сверху
                    Color(hex: "#000000") // черный снизу
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Result icon
                VStack(spacing: 16) {
                    Image(systemName: resultIcon)
                        .font(.system(size: 80))
                        .foregroundStyle(resultGradient)
                    
                    LocalizedText("mistakes.result.title")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }
                
                // Score details
                VStack(spacing: 20) {
                    // Main score
                    VStack(spacing: 8) {
                        Text("\(Int(result.percentage))%")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundStyle(resultColor)
                        
                        LocalizedText("mistakes.result.correctAnswers")
                            .font(.title3)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    
                    // Detailed stats
                    VStack(spacing: 12) {
                        StatRow(
                            title: localizationProvider.localizedString(for: "mistakes.result.totalQuestions"),
                            value: "\(result.totalQuestions)"
                        )
                        
                        StatRow(
                            title: localizationProvider.localizedString(for: "mistakes.result.correctAnswers"),
                            value: "\(result.correctAnswers)"
                        )
                        
                        StatRow(
                            title: localizationProvider.localizedString(for: "mistakes.result.timeSpent"),
                            value: formatTime(result.timeSpent)
                        )
                    }
                    .padding(DesignTokens.Spacing.xxl)
                    .background(
                        // Прозрачная рамка с фиолетовым свечением (как на главном экране)
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
                    )
                    .background(DesignTokens.Colors.cardBackground)
                }
            
                // Improvement badge
                if result.percentage >= 70 {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(DesignTokens.Colors.iconGreen)
                        LocalizedText("mistakes.result.improvement")
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.iconGreen)
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(DesignTokens.Colors.iconGreen.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                    .stroke(DesignTokens.Colors.iconGreen.opacity(0.3), lineWidth: 1)
                            )
                    )
                } else if result.percentage < 50 {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(DesignTokens.Colors.iconOrange)
                        LocalizedText("mistakes.result.needMorePractice")
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.iconOrange)
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(DesignTokens.Colors.iconOrange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                    .stroke(DesignTokens.Colors.iconOrange.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: onRepeat) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            LocalizedText("mistakes.result.repeatAgain")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            ZStack {
                                // Градиентный фон кнопки (красный для повторения)
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignTokens.Colors.redGradientStart,
                                        DesignTokens.Colors.redGradientEnd
                                    ]),
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
                            color: DesignTokens.Colors.redGradientStart.opacity(0.5),
                            radius: 12,
                            y: 6
                        )
                    }
                    
                    Button(action: onBackToStart) {
                        HStack {
                            Image(systemName: "house.fill")
                            LocalizedText("mistakes.result.backToStart")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            ZStack {
                                // Градиентный фон кнопки (синий для возврата)
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignTokens.Colors.blueGradientStart,
                                        DesignTokens.Colors.blueGradientEnd
                                    ]),
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
                            color: DesignTokens.Colors.blueGradientStart.opacity(0.5),
                            radius: 12,
                            y: 6
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
            }
            .padding(DesignTokens.Spacing.xxl)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.clear, for: .navigationBar) // прозрачный toolbar для градиента
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private var resultIcon: String {
        switch result.percentage {
        case 80...:
            return "checkmark.circle.fill"
        case 60..<80:
            return "arrow.up.circle.fill"
        case 40..<60:
            return "arrow.down.circle.fill"
        default:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var resultColor: Color {
        switch result.percentage {
        case 80...:
            return DesignTokens.Colors.iconGreen
        case 60..<80:
            return DesignTokens.Colors.iconBlue
        case 40..<60:
            return DesignTokens.Colors.iconOrange
        default:
            return DesignTokens.Colors.iconRed
        }
    }
    
    private var resultGradient: LinearGradient {
        switch result.percentage {
        case 80...:
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignTokens.Colors.greenGradientStart,
                    DesignTokens.Colors.greenGradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 60..<80:
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignTokens.Colors.blueGradientStart,
                    DesignTokens.Colors.blueGradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 40..<60:
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignTokens.Colors.amberGradientStart,
                    DesignTokens.Colors.amberGradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [
                    DesignTokens.Colors.redGradientStart,
                    DesignTokens.Colors.redGradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}

#Preview {
    let result = QuizResult(totalQuestions: 10, correctAnswers: 7, percentage: 70, timeSpent: 80)
    MistakesResultView(result: result, onRepeat: {}, onBackToStart: {})
}
