//
//  ProfileSyncSectionView.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
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
        if manager.isSignedIn {
            unifiedSyncSection
        } else {
            questionsSyncSection
        }
    }
    
    // MARK: - Unified Sync Section
    private var unifiedSyncSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
            Text("profile.sync.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            // CloudKit Statistics Sync Section
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: ProfileViewHelpers.syncIcon(for: manager.syncState))
                        .font(.system(size: DesignTokens.Sizes.iconSmall))
                        .foregroundColor(ProfileViewHelpers.syncColor(for: manager.syncState))
                    
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
                                .foregroundColor(DesignTokens.Colors.warning)
                            
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
                                await manager.refreshFromCloud(mergeStrategy: .newest)
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
                            await manager.refreshFromCloud(mergeStrategy: .newest)
                        }
                    }
                    .disabled(isResettingProfile || manager.isLoading)
                }
            }
            
            // Divider
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Questions Sync Section
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("stats.sync.questions.status".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
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
                                .foregroundColor(DesignTokens.Colors.iconGreen)
                            if newQuestionsCount > 0 {
                                Text("+\(newQuestionsCount)")
                                    .font(DesignTokens.Typography.label)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignTokens.Colors.iconGreen)
                            }
                        }
                    } else {
                        Text("stats.sync.upToDate".localized)
                            .font(DesignTokens.Typography.secondaryRegular)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.iconBlue)
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
    
    // MARK: - Questions Sync Section (for non-signed in users)
    private var questionsSyncSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("stats.sync.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("stats.sync.questions.status".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    Spacer()
                    if remoteService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(DesignTokens.Colors.textSecondary)
                    } else if remoteService.hasUpdates {
                        Text("stats.sync.available".localized)
                            .font(DesignTokens.Typography.secondaryRegular)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.iconGreen)
                    } else {
                        Text("stats.sync.upToDate".localized)
                            .font(DesignTokens.Typography.secondaryRegular)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.iconBlue)
                    }
                }
                
                if remoteService.hasUpdates && newQuestionsCount > 0 {
                    HStack {
                        Text("stats.sync.newQuestions.title".localized)
                            .font(DesignTokens.Typography.label)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Spacer()
                        Text("+\(newQuestionsCount)")
                            .font(DesignTokens.Typography.label)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.iconGreen)
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
        .padding(DesignTokens.Spacing.xxl)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }
}

