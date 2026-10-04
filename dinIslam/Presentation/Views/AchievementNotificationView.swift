//
//  AchievementNotificationView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct AchievementNotificationView: View {
    let achievement: Achievement
    /// Номер достижения в очереди и сколько их всего
    var position: Int = 1
    var total: Int = 1
    let onClose: () -> Void
    @Environment(\.localizationProvider) private var localizationProvider
    
    private var isLast: Bool {
        position >= total
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon and Title
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: DesignTokens.Sizes.iconXLarge, weight: .medium))
                        .foregroundStyle(achievement.color)
                }
                
                VStack(spacing: 4) {
                    if total > 1 {
                        Text(String(
                            format: localizationProvider.localizedString(for: "achievements.notification.counter"),
                            position,
                            total
                        ))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    
                    Text(localizationProvider.localizedString(for: "achievements.congratulations"))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(achievement.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Description
            Text(achievement.type.notification(using: localizationProvider))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Close Button
            Button(action: onClose) {
                Text(localizationProvider.localizedString(for: isLast ? "settings.done" : "achievements.notification.next"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(achievement.color, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            }
            .padding(.horizontal)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.overlayCard)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.overlayCard)
                        .stroke(achievement.color.opacity(0.3), lineWidth: 2)
                )
        )
        .padding(.horizontal, 32)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        AchievementNotificationView(
            achievement: Achievement(
                id: "test",
                title: LocalizationManager().localizedString(for: "achievements.firstQuiz.title"),
                description: LocalizationManager().localizedString(for: "achievements.firstQuiz.description"),
                icon: "play.circle.fill",
                color: .blue,
                type: .firstQuiz,
                requirement: 1,
                isUnlocked: true,
                unlockedDate: Date()
            ),
            position: 1,
            total: 3,
            onClose: {}
        )
    }
}
