//
//  BankCompletionView.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import SwiftUI

struct BankCompletionView: View {
    let totalQuestions: Int
    let onStartOver: () -> Void
    let onStartReview: () -> Void
    
    var body: some View {
        ZStack {
            // Background - очень темный градиент с оттенками индиго/фиолетового
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#0a0a1a"), // темно-индиго сверху
                    Color(hex: "#000000") // черный снизу
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxxl) {
                    Spacer()
                        .frame(height: DesignTokens.Spacing.xxxl)
                    
                    // Иконка завершения
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignTokens.Colors.iconGreen.opacity(0.3),
                                        DesignTokens.Colors.iconGreen.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(
                                color: DesignTokens.Colors.iconGreen.opacity(0.5),
                                radius: 20,
                                x: 0,
                                y: 0
                            )
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(DesignTokens.Colors.iconGreen)
                    }
                    .padding(.bottom, DesignTokens.Spacing.lg)
                    
                    // Заголовок
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Text("bank.completion.title".localized)
                            .font(DesignTokens.Typography.h1)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("bank.completion.subtitle".localized)
                            .font(DesignTokens.Typography.bodyRegular)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignTokens.Spacing.xl)
                    }
                    
                    // Статистика
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text("\(totalQuestions) / \(totalQuestions)")
                            .font(DesignTokens.Typography.h2)
                            .foregroundStyle(DesignTokens.Colors.iconGreen)
                        
                        Text("bank.completion.questionsCompleted".localized)
                            .font(DesignTokens.Typography.label)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    .padding(DesignTokens.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(DesignTokens.Colors.iconGreen.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                    .stroke(
                                        DesignTokens.Colors.iconGreen.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    
                    Spacer()
                        .frame(height: DesignTokens.Spacing.xxl)
                    
                    // Кнопки действий
                    VStack(spacing: DesignTokens.Spacing.md) {
                        // Кнопка "Начать заново"
                        Button(action: onStartOver) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                                    .foregroundColor(.white)
                                
                                Text("bank.completion.startOver".localized)
                                    .font(DesignTokens.Typography.secondarySemibold)
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: DesignTokens.Sizes.iconSmall))
                                    .foregroundColor(.white)
                            }
                            .padding(DesignTokens.Spacing.lg)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    // Градиентный фон кнопки
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            DesignTokens.Colors.quizButtonGradientStart,
                                            DesignTokens.Colors.quizButtonGradientEnd
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
                                color: DesignTokens.Colors.quizButtonGradientStart.opacity(0.5),
                                radius: 12,
                                y: 6
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // Кнопка "Повторение"
                        Button(action: onStartReview) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "repeat")
                                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                                    .foregroundColor(.white)
                                
                                Text("bank.completion.review".localized)
                                    .font(DesignTokens.Typography.secondarySemibold)
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: DesignTokens.Sizes.iconSmall))
                                    .foregroundColor(.white)
                            }
                            .padding(DesignTokens.Spacing.lg)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    // Градиентный фон кнопки
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            DesignTokens.Colors.examButtonGradientStart,
                                            DesignTokens.Colors.examButtonGradientEnd
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
                                color: DesignTokens.Colors.examButtonGradientStart.opacity(0.5),
                                radius: 12,
                                y: 6
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    
                    Spacer()
                        .frame(height: DesignTokens.Spacing.xxxl)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        BankCompletionView(
            totalQuestions: 283,
            onStartOver: {},
            onStartReview: {}
        )
    }
}

