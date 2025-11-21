//
//  ProfileSyncSectionView.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import SwiftUI

struct ProfileSyncSectionView: View {
    @Bindable var manager: ProfileManager
    @Environment(\.remoteQuestionsService) var remoteService: RemoteQuestionsService
    @Environment(\.settingsManager) private var settingsManager
    
    let isResettingProfile: Bool
    let onSyncQuestions: () async -> Void
    let onCheckForUpdates: () async -> Void
    
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
                
                MinimalButton(
                    icon: "icloud.fill",
                    title: "profile.sync.refresh".localized,
                    foregroundColor: DesignTokens.Colors.iconBlue
                ) {
                    Task { @MainActor [manager] in
                        await manager.refreshFromCloud(mergeStrategy: .newest)
                    }
                }
                .disabled(isResettingProfile || manager.isLoading)
                .opacity((isResettingProfile || manager.isLoading) ? 0.6 : 1.0)
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
                            if remoteService.remoteQuestionsCount > remoteService.cachedQuestionsCount {
                                Text("+\(remoteService.remoteQuestionsCount - remoteService.cachedQuestionsCount)")
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
                        foregroundColor: DesignTokens.Colors.iconGreen
                    ) {
                        Task { @MainActor in
                            await onSyncQuestions()
                        }
                    }
                    .disabled(remoteService.isLoading)
                    .opacity(remoteService.isLoading ? 0.6 : 1.0)
                } else {
                    MinimalButton(
                        icon: "tray.and.arrow.down.fill",
                        title: "stats.sync.check".localized,
                        foregroundColor: DesignTokens.Colors.iconBlue
                    ) {
                        Task { @MainActor in
                            await onCheckForUpdates()
                        }
                    }
                    .disabled(remoteService.isLoading)
                    .opacity(remoteService.isLoading ? 0.6 : 1.0)
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
        .background(
            // Прозрачная рамка с фиолетовым свечением (как на главном экране)
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
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
                
                if remoteService.hasUpdates {
                    HStack {
                        Text("stats.sync.newQuestions.title".localized)
                            .font(DesignTokens.Typography.label)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Spacer()
                        Text("+\(remoteService.remoteQuestionsCount - remoteService.cachedQuestionsCount)")
                            .font(DesignTokens.Typography.label)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.iconGreen)
                    }
                }
                
                if remoteService.hasUpdates {
                    MinimalButton(
                        icon: "arrow.down.circle",
                        title: "stats.sync.sync".localized,
                        foregroundColor: DesignTokens.Colors.iconGreen
                    ) {
                        Task { @MainActor in
                            await onSyncQuestions()
                        }
                    }
                    .disabled(remoteService.isLoading)
                    .opacity(remoteService.isLoading ? 0.6 : 1.0)
                } else {
                    MinimalButton(
                        icon: "tray.and.arrow.down.fill",
                        title: "stats.sync.check".localized,
                        foregroundColor: DesignTokens.Colors.iconBlue
                    ) {
                        Task { @MainActor in
                            await onCheckForUpdates()
                        }
                    }
                    .disabled(remoteService.isLoading)
                    .opacity(remoteService.isLoading ? 0.6 : 1.0)
                }
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .background(
            // Прозрачная рамка с фиолетовым свечением (как на главном экране)
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
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
    }
}

