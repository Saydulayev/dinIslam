//
//  AchievementsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct AchievementsView: View {
    @StateObject private var achievementManager = AchievementManager()
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject private var settingsManager: SettingsManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(achievementManager.achievements) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
                .padding()
            }
            .navigationTitle(LocalizationManager.shared.localizedString(for: "achievements.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString(for: "settings.done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject private var settingsManager: SettingsManager
    
    private var isUnlocked: Bool {
        achievement.isUnlocked
    }
    
    private var progress: AchievementProgress {
        // Получаем статистику для расчета прогресса
        let statsManager = StatsManager()
        let achievementManager = AchievementManager()
        return achievementManager.getAchievementProgress(for: achievement.type, stats: statsManager.stats)
    }
    
    private var cardColor: Color {
        if isUnlocked {
            return achievement.color
        } else {
            return .gray
        }
    }
    
    private var iconColor: Color {
        if isUnlocked {
            return cardColor
        } else {
            return .gray
        }
    }
    
    private var iconBackgroundColor: Color {
        if isUnlocked {
            return cardColor.opacity(0.2)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isUnlocked ? .primary : .secondary)
                    
                    Spacer()
                    
                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                if isUnlocked, let unlockedDate = achievement.unlockedDate {
                    Text(LocalizationManager.shared.localizedString(for: "achievements.unlocked") + " " + 
                         unlockedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        // Прогресс-бар
                        ProgressView(value: progress.progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: achievement.color))
                            .scaleEffect(x: 1, y: 0.8)
                        
                        // Текст прогресса
                        HStack {
                            Text("\(progress.currentProgress)/\(progress.requirement)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(achievement.color)
                            
                            Spacer()
                            
                            Text(getProgressDescription())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardColor.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(isUnlocked ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.3), value: isUnlocked)
    }
    
    private func getProgressDescription() -> String {
        switch achievement.type {
        case .firstQuiz:
            return LocalizationManager.shared.localizedString(for: "achievements.progress.quiz")
        case .perfectScore:
            return LocalizationManager.shared.localizedString(for: "achievements.progress.perfect")
        case .speedRunner:
            return LocalizationManager.shared.localizedString(for: "achievements.progress.speed")
        case .scholar, .explorer:
            return LocalizationManager.shared.localizedString(for: "achievements.progress.questions")
        case .dedicated, .master, .legend:
            return LocalizationManager.shared.localizedString(for: "achievements.progress.quizzes")
        case .streak:
            return LocalizationManager.shared.localizedString(for: "achievements.progress.streak")
        case .perfectionist:
            return LocalizationManager.shared.localizedString(for: "achievements.progress.perfects")
        }
    }
}

#Preview {
    AchievementsView()
}
