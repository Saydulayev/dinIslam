//
//  AchievementsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct AchievementsView: View {
    @ObservedObject var achievementManager: AchievementManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.settingsManager) private var settingsManager
    @Environment(\.statsManager) private var statsManager: StatsManager
    @Environment(\.localizationProvider) private var localizationProvider
    @State private var showingResetAlert = false
    @State private var selectedAchievement: Achievement?
    
    init(achievementManager: AchievementManager? = nil) {
        // Use the provided manager, or create a fallback (for previews)
        _achievementManager = ObservedObject(wrappedValue: achievementManager ?? AchievementManager(
            notificationManager: NotificationManager(),
            localizationProvider: LocalizationManager()
        ))
    }
    
    private var achievementsList: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.lg) {
                ForEach(achievementManager.achievements) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        onTap: { selectedAchievement = achievement }
                    )
                }
                
                // Разрушительное действие — внизу списка, а не в верхней панели
                MinimalButton(
                    icon: "arrow.counterclockwise",
                    title: "achievements.reset".localized,
                    role: .destructive
                ) {
                    showingResetAlert = true
                }
                .padding(.top, DesignTokens.Spacing.lg)
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.top, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxxl)
        }
    }
    
    private var expandedCardOverlay: some View {
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
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            achievementsList
        }
        .navigationTitle("achievements.title".localized)
        .navigationBarTitleDisplayMode(.inline)
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
        .overlay(expandedCardOverlay)
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let onTap: () -> Void
    @Environment(\.localizationProvider) private var localizationProvider
    @Environment(\.settingsManager) private var settingsManager
    @Environment(\.achievementManager) private var achievementManager: AchievementManager
    @Environment(\.statsManager) private var statsManager: StatsManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
        // Открыть подробности можно только у полученного достижения
        if isUnlocked {
            Button {
                withAnimation(.dsSpring(reduceMotion: reduceMotion)) {
                    onTap()
                }
            } label: {
                cardContent
            }
            .buttonStyle(.plain)
        } else {
            cardContent
                .accessibilityElement(children: .combine)
        }
    }
    
    private var cardContent: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: DesignTokens.Sizes.iconLarge, weight: .semibold))
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
                
                Text(achievement.displayDescription(using: localizationProvider))
                    .font(DesignTokens.Typography.label)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                
                if isUnlocked, let unlockedDate = achievement.unlockedDate {
                    Text(localizationProvider.localizedString(for: "achievements.unlocked") + " " + 
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
            // Прозрачная рамка с фиолетовым свечением (как на главном экране)
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Colors.iconPurpleLight.opacity(isUnlocked ? 0.5 : 0.3),
                            DesignTokens.Colors.iconPurpleLight.opacity(isUnlocked ? 0.2 : 0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .shadow(
                    color: DesignTokens.Colors.iconPurpleLight.opacity(isUnlocked ? 0.3 : 0.15),
                    radius: 12,
                    x: 0,
                    y: 0
                )
        )
        // Без общей прозрачности: серый текст на 0.6 не проходит по контрасту (≈3.4:1),
        // а заблокированность и так видна по серой иконке, заголовку и прогрессу
        .animation(.easeInOut(duration: 0.3), value: isUnlocked)
        .contentShape(Rectangle())
    }
}

struct ExpandedAchievementCard: View {
    let achievement: Achievement
    @Binding var isPresented: Bool
    @Environment(\.localizationProvider) private var localizationProvider
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            // Icon and Title
            VStack(spacing: DesignTokens.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(achievement.color.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: DesignTokens.Sizes.iconXXLarge, weight: .semibold))
                        .foregroundColor(achievement.color)
                }
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text(achievement.title)
                        .font(DesignTokens.Typography.displayTitle)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.displayDescription(using: localizationProvider))
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    if let unlockedDate = achievement.unlockedDate {
                        Text(localizationProvider.localizedString(for: "achievements.unlocked") + " " + 
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
                // Share Button - в стиле MinimalButton
                MinimalButton(
                    icon: "square.and.arrow.up",
                    title: "achievements.share".localized
                ) {
                    shareAchievement()
                }
                
                // Close Button - в стиле MinimalButton
                MinimalButton(
                    icon: "checkmark.square",
                    title: localizationProvider.localizedString(for: "settings.done"),
                    role: .secondary
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .background(
            ZStack {
                // Прозрачный темный фон
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
                    .fill(Color.black.opacity(0.4))
                    .background(
                        // Блюр эффект для глубины
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
                            .fill(.ultraThinMaterial)
                    )
                
                // Рамка с фиолетовым свечением
                GlowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge))
        .shadow(
            color: achievement.color.opacity(0.3),
            radius: 20,
            y: 12
        )
        .padding(.horizontal, DesignTokens.Spacing.xxxl)
        .scaleEffect(isPresented || reduceMotion ? 1.0 : 0.8)
        .opacity(isPresented ? 1.0 : 0.0)
        .animation(.dsSpring(reduceMotion: reduceMotion), value: isPresented)
    }
    
    // MARK: - Helper
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
        // Карточка уже 1080×1920 точек: масштаб экрана (×3) дал бы 3240×5760 пикселей (~75 МБ в памяти)
        renderer.scale = 1
        
        // Устанавливаем размер изображения (Instagram story size: 1080x1920)
        let targetSize = CGSize(width: 1080, height: 1920)
        renderer.proposedSize = .init(width: targetSize.width, height: targetSize.height)
        
        // Даем время на рендеринг
        return renderer.uiImage
    }
    
    private func generateShareText() -> String {
        let appName = localizationProvider.localizedString(for: "app.name")
        let unlockedDate = achievement.unlockedDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
        
        return """
        🏆 \(achievement.title)
        
        \(achievement.displayDescription(using: localizationProvider))
        
        \(localizationProvider.localizedString(for: "achievements.share.text")) \(unlockedDate)
        
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

/// Картинка для шаринга: холст 1080×1920 пикселей, поэтому размеры заданы
/// числами под этот холст, а не токенами интерфейса
struct ShareableAchievementCardView: View {
    let achievement: Achievement
    @Environment(\.localizationProvider) private var localizationProvider
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 60) {
                // App Logo at top
                VStack(spacing: 20) {
                    Image("image")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180)
                    
                    Text(localizationProvider.localizedString(for: "app.name"))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 80)
                
                Spacer()
                
                // Achievement Card - УВЕЛИЧЕНА
                VStack(spacing: 50) {
                    // Icon - УВЕЛИЧЕН
                    ZStack {
                        Circle()
                            .fill(achievement.color.opacity(0.2))
                            .frame(width: 280, height: 280)
                        
                        Image(systemName: achievement.icon)
                            .font(.system(size: 140, weight: .semibold))
                            .foregroundColor(achievement.color)
                    }
                    
                    // Title and Description - УВЕЛИЧЕНЫ ШРИФТЫ
                    VStack(spacing: 24) {
                        Text(achievement.title)
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                        
                        Text(achievement.displayDescription(using: localizationProvider))
                            .font(.system(size: 36))
                            .foregroundColor(Color.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .padding(.horizontal, 40)
                        
                        if let unlockedDate = achievement.unlockedDate {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(DesignTokens.Colors.iconGreen)
                                
                                Text(localizationProvider.localizedString(for: "achievements.unlocked") + " " + 
                                     unlockedDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(DesignTokens.Colors.iconGreen)
                            }
                            .padding(.top, 16)
                        }
                    }
                }
                .padding(60)
                .background(
                    ZStack {
                        // Прозрачная рамка с фиолетовым свечением (как на главном экране)
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.white.opacity(0.05))
                        
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignTokens.Colors.iconPurpleLight.opacity(0.6),
                                        DesignTokens.Colors.iconPurpleLight.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    }
                )
                .shadow(
                    color: DesignTokens.Colors.iconPurpleLight.opacity(0.5),
                    radius: 30,
                    x: 0,
                    y: 0
                )
                .padding(.horizontal, 80)
                
                Spacer()
                
                // Trophy icon at bottom - УВЕЛИЧЕН
                HStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundColor(achievement.color)
                    
                    Text("achievements.singular".localized)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 80)
            }
        }
        .frame(width: 1080, height: 1920) // Instagram story size
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
            .environment(\.achievementManager, AchievementManager(notificationManager: NotificationManager()))
            .environment(\.settingsManager, SettingsManager())
            .environment(\.localizationProvider, LocalizationManager())
    }
}

