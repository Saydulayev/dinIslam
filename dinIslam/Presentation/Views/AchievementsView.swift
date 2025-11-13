//
//  AchievementsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var achievementManager: AchievementManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.settingsManager) private var settingsManager
    @Environment(\.statsManager) private var statsManager: StatsManager
    @State private var showingResetAlert = false
    @State private var selectedAchievement: Achievement?
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    DesignTokens.Colors.background1,
                    DesignTokens.Colors.background2
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.lg) {
                    ForEach(achievementManager.achievements) { achievement in
                        AchievementCard(
                            achievement: achievement,
                            onTap: { selectedAchievement = achievement }
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
        .navigationTitle("achievements.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("achievements.reset".localized) {
                    showingResetAlert = true
                }
                .font(DesignTokens.Typography.secondarySemibold)
                .foregroundColor(DesignTokens.Colors.iconRed)
            }
        }
        .toolbarBackground(DesignTokens.Colors.background1, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert(
            "achievements.reset.confirm.title".localized,
            isPresented: $showingResetAlert
        ) {
            Button("achievements.reset.confirm.cancel".localized, role: .cancel) {
                // Cancel action
            }
            Button("achievements.reset.confirm.ok".localized, role: .destructive) {
                achievementManager.resetAllAchievements()
                statsManager.resetAchievementProgress()
            }
        } message: {
            Text("achievements.reset.confirm.message".localized)
        }
        .overlay(
            // Expanded Achievement Card Overlay
            Group {
                if let achievement = selectedAchievement, achievement.isUnlocked {
                    ZStack {
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    selectedAchievement = nil
                                }
                            }
                        
                        ExpandedAchievementCard(
                            achievement: achievement,
                            isPresented: Binding(
                                get: { selectedAchievement != nil },
                                set: { if !$0 { selectedAchievement = nil } }
                            )
                        )
                    }
                }
            }
        )
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let onTap: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.settingsManager) private var settingsManager
    @EnvironmentObject private var achievementManager: AchievementManager
    @Environment(\.statsManager) private var statsManager: StatsManager
    
    private var isUnlocked: Bool {
        achievement.isUnlocked
    }
    
    private var progress: AchievementProgress {
        return achievementManager.getAchievementProgress(for: achievement.type, stats: statsManager.stats)
    }
    
    private var iconColor: Color {
        if isUnlocked {
            return achievement.color
        } else {
            return DesignTokens.Colors.textSecondary
        }
    }
    
    private var iconBackgroundColor: Color {
        if isUnlocked {
            return achievement.color.opacity(0.2)
        } else {
            return DesignTokens.Colors.textSecondary.opacity(0.2)
        }
    }
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
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
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text(achievement.title)
                        .font(DesignTokens.Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(isUnlocked ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                    
                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignTokens.Colors.iconGreen)
                            .font(.system(size: DesignTokens.Sizes.iconMedium))
                    }
                }
                
                Text(achievement.displayDescription)
                    .font(DesignTokens.Typography.label)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                
                if isUnlocked, let unlockedDate = achievement.unlockedDate {
                    Text(LocalizationManager.shared.localizedString(for: "achievements.unlocked") + " " + 
                         unlockedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(DesignTokens.Typography.label)
                    .foregroundColor(DesignTokens.Colors.iconGreen)
                    .fontWeight(.medium)
                    .padding(.top, DesignTokens.Spacing.xs)
                } else {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        // Прогресс-бар
                        ProgressView(value: progress.progressPercentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: achievement.color))
                            .scaleEffect(x: 1, y: 0.8)
                        
                        // Текст прогресса
                        HStack {
                            Text("\(progress.currentProgress)/\(progress.requirement)")
                                .font(DesignTokens.Typography.label)
                                .fontWeight(.semibold)
                                .foregroundColor(achievement.color)
                            
                            Spacer()
                        }
                    }
                    .padding(.top, DesignTokens.Spacing.xs)
                }
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                .fill(DesignTokens.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                        .stroke(
                            isUnlocked ? achievement.color.opacity(0.3) : DesignTokens.Colors.borderSubtle,
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: DesignTokens.Shadows.card,
            radius: DesignTokens.Shadows.cardRadius,
            y: DesignTokens.Shadows.cardY
        )
        .opacity(isUnlocked ? 1.0 : 0.7)
        .animation(.easeInOut(duration: 0.3), value: isUnlocked)
        .onTapGesture {
            if isUnlocked {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    onTap()
                }
            }
        }
    }
}

struct ExpandedAchievementCard: View {
    let achievement: Achievement
    @Binding var isPresented: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            // Icon and Title
            VStack(spacing: DesignTokens.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(achievement.color)
                }
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text(achievement.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.displayDescription)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    if let unlockedDate = achievement.unlockedDate {
                        Text(LocalizationManager.shared.localizedString(for: "achievements.unlocked") + " " + 
                             unlockedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.iconGreen)
                        .fontWeight(.medium)
                        .padding(.top, DesignTokens.Spacing.xs)
                    }
                }
            }
            
            // Buttons
            VStack(spacing: DesignTokens.Spacing.sm) {
                // Share Button - стилизованная
                Button(action: {
                    shareAchievement()
                }) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: DesignTokens.Sizes.iconSmall))
                        Text("achievements.share".localized)
                            .font(DesignTokens.Typography.secondaryRegular)
                    }
                    .foregroundColor(achievement.color)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(DesignTokens.Colors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                    .stroke(achievement.color.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                
                // Close Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Text(LocalizationManager.shared.localizedString(for: "settings.done"))
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                .fill(DesignTokens.Colors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                                        .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
                .fill(DesignTokens.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
                        .stroke(achievement.color.opacity(0.5), lineWidth: 2)
                )
        )
        .shadow(
            color: Color.black.opacity(0.5),
            radius: 20,
            y: 10
        )
        .padding(.horizontal, DesignTokens.Spacing.xxxl)
        .scaleEffect(isPresented ? 1.0 : 0.8)
        .opacity(isPresented ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
    }
    
    private func shareAchievement() {
        guard let shareImage = generateShareImage() else {
            // Fallback to text if image generation fails
            let shareText = generateShareText()
            presentShareSheet(items: [shareText])
            return
        }
        
        presentShareSheet(items: [shareImage])
    }
    
    private func generateShareImage() -> UIImage? {
        let shareableCard = ShareableAchievementCardView(achievement: achievement)
        
        // Используем ImageRenderer для конвертации View в UIImage
        let renderer = ImageRenderer(content: shareableCard)
        renderer.scale = UIScreen.main.scale
        
        // Устанавливаем размер изображения
        // Размер карточки 1000x1200 + padding 60 с каждой стороны = 1120x1320
        let targetSize = CGSize(width: 1120, height: 1320)
        renderer.proposedSize = .init(width: targetSize.width, height: targetSize.height)
        
        // Даем время на рендеринг
        return renderer.uiImage
    }
    
    private func generateShareText() -> String {
        let appName = LocalizationManager.shared.localizedString(for: "app.name")
        let unlockedDate = achievement.unlockedDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
        
        return """
        🏆 \(achievement.title)
        
        \(achievement.displayDescription)
        
        \(LocalizationManager.shared.localizedString(for: "achievements.share.text")) \(unlockedDate)
        
        \(appName)
        """
    }
    
    private func presentShareSheet(items: [Any]) {
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            // Для iPad нужна точка привязки
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

struct ShareableAchievementCardView: View {
    let achievement: Achievement
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 40) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.color.opacity(0.2))
                    .frame(width: 200, height: 200)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 100, weight: .semibold))
                    .foregroundColor(achievement.color)
            }
            .padding(.top, 60)
            
            // Title and Description
            VStack(spacing: 20) {
                Text(achievement.title)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(Color.black)
                    .multilineTextAlignment(.center)
                
                Text(achievement.displayDescription)
                    .font(.system(size: 32))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
                
                if let unlockedDate = achievement.unlockedDate {
                    Text(LocalizationManager.shared.localizedString(for: "achievements.unlocked") + " " + 
                         unlockedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.0, green: 0.7, blue: 0.0))
                    .fontWeight(.medium)
                    .padding(.top, 16)
                }
            }
            
            Spacer()
            
            // App Logo and Name at bottom
            VStack(spacing: 20) {
                Image("image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                
                Text(LocalizationManager.shared.localizedString(for: "app.name"))
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(achievement.color)
            }
            .padding(.bottom, 60)
        }
        .frame(width: 1000, height: 1200)
        .background(
            ZStack {
                // Фон (белый)
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                
                // Обводка
                RoundedRectangle(cornerRadius: 24)
                    .stroke(achievement.color.opacity(0.3), lineWidth: 3)
            }
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(60)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
            .environmentObject(AchievementManager.shared)
            .environment(\.settingsManager, SettingsManager())
    }
}

