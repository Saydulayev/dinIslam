//
//  AchievementNotificationView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct AchievementNotificationView: View {
    let achievement: Achievement
    @Binding var isPresented: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon and Title
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(achievement.color)
                }
                
                VStack(spacing: 4) {
                    Text(LocalizationManager.shared.localizedString(for: "achievements.congratulations"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(achievement.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Description
            Text(achievement.type.localizedNotification)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Close Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }) {
                Text(LocalizationManager.shared.localizedString(for: "settings.done"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(achievement.color, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(achievement.color.opacity(0.3), lineWidth: 2)
                )
        )
        .padding(.horizontal, 32)
        .scaleEffect(isPresented ? 1.0 : 0.8)
        .opacity(isPresented ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        AchievementNotificationView(
            achievement: Achievement(
                id: "test",
                title: LocalizationManager.shared.localizedString(for: "achievements.firstQuiz.title"),
                description: LocalizationManager.shared.localizedString(for: "achievements.firstQuiz.description"),
                icon: "play.circle.fill",
                color: .blue,
                type: .firstQuiz,
                requirement: 1,
                isUnlocked: true,
                unlockedDate: Date()
            ),
            isPresented: .constant(true)
        )
    }
}
