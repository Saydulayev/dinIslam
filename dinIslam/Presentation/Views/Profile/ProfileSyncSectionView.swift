//
//  ProfileSyncSectionView.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import SwiftUI

struct ProfileSyncSectionView: View {
    @Bindable var manager: ProfileManager
    @Environment(\.remoteQuestionsService) var remoteService: EnhancedRemoteQuestionsService
    @Environment(\.settingsManager) private var settingsManager
    
    let isResettingProfile: Bool
    let onSyncQuestions: () async -> Void
    let onCheckForUpdates: () async -> Void
    
    /// Прирост вопросов в обновлении; если вопросы удалили, разница отрицательная — «+N» не показываем
    private var newQuestionsCount: Int {
        remoteService.remoteQuestionsCount - remoteService.cachedQuestionsCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
            Text("profile.sync.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            if manager.isSyncEnabled {
                statisticsSyncSection
            } else {
                iCloudUnavailableSection
            }
            
            // Divider
            Divider()
                .overlay(Color.white.opacity(0.1))
            
            questionsSection
            
            if isResettingProfile {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(DesignTokens.Colors.textSecondary)
                    Text("profile.sync.reset.inProgress".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }
    
    // MARK: - iCloud Statistics Sync
    private var iCloudUnavailableSection: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            Image(systemName: manager.iCloudStatus == .checking ? "icloud" : "icloud.slash")
                .font(.system(size: DesignTokens.Sizes.iconSmall))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            
            Text(ProfileViewHelpers.iCloudStatusMessage(for: manager.iCloudStatus))
                .font(DesignTokens.Typography.secondaryRegular)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var statisticsSyncSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: ProfileViewHelpers.syncIcon(for: manager.syncState))
                    .font(.system(size: DesignTokens.Sizes.iconSmall))
                    .foregroundStyle(ProfileViewHelpers.syncColor(for: manager.syncState))
                
                Text(ProfileViewHelpers.syncMessage(for: manager, settingsManager: settingsManager))
                    .font(DesignTokens.Typography.secondaryRegular)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            
            // Показываем более заметное сообщение об ошибке при неудачной синхронизации
            if case .failed(let message) = manager.syncState {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: DesignTokens.Sizes.iconSmall))
                            .foregroundStyle(DesignTokens.Colors.warning)
                        
                        Text(message)
                            .font(DesignTokens.Typography.secondaryRegular)
                            .foregroundStyle(DesignTokens.Colors.warning)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                            .fill(DesignTokens.Colors.warning.opacity(0.1))
                    )
                    
                    MinimalButton(
                        icon: "arrow.clockwise",
                        title: "profile.sync.retry".localized,
                        role: .warning
                    ) {
                        Task { @MainActor [manager] in
                            await manager.syncNow()
                        }
                    }
                    .disabled(isResettingProfile || manager.isLoading)
                }
            } else {
                MinimalButton(
                    icon: "icloud.fill",
                    title: "profile.sync.refresh".localized
                ) {
                    Task { @MainActor [manager] in
                        await manager.syncNow()
                    }
                }
                .disabled(isResettingProfile || manager.isLoading)
            }
        }
    }
    
    // MARK: - Questions Sync
    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("stats.sync.questions.status".localized)
                    .font(DesignTokens.Typography.secondaryRegular)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                Spacer()
                if remoteService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(DesignTokens.Colors.textSecondary)
                } else if remoteService.hasUpdates {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Text("stats.sync.available".localized)
                            .font(DesignTokens.Typography.secondaryRegular)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignTokens.Colors.iconGreen)
                        if newQuestionsCount > 0 {
                            Text("+\(newQuestionsCount)")
                                .font(DesignTokens.Typography.label)
                                .fontWeight(.semibold)
                                .foregroundStyle(DesignTokens.Colors.iconGreen)
                        }
                    }
                } else {
                    Text("stats.sync.upToDate".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignTokens.Colors.iconBlue)
                }
            }
            
            if remoteService.hasUpdates {
                MinimalButton(
                    icon: "arrow.down.circle",
                    title: "stats.sync.sync".localized,
                    role: .success
                ) {
                    Task { @MainActor in
                        await onSyncQuestions()
                    }
                }
                .disabled(remoteService.isLoading)
            } else {
                MinimalButton(
                    icon: "tray.and.arrow.down.fill",
                    title: "stats.sync.check".localized
                ) {
                    Task { @MainActor in
                        await onCheckForUpdates()
                    }
                }
                .disabled(remoteService.isLoading)
            }
        }
    }
}
