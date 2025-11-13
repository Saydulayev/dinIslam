//
//  ProfileView.swift
//  dinIslam
//
//  Created by GPT-5 Codex on 09.11.25.
//

import AuthenticationServices
import Observation
import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.profileManager) private var profileManager
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var showResetConfirmation = false
    @State private var isResettingProfile = false

    var body: some View {
        @Bindable var manager = profileManager
        
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
                VStack(spacing: DesignTokens.Spacing.xxxl) {
                    profileCard(manager: manager)
                    
                    if manager.isSignedIn {
                        progressSection(progress: manager.progress)
                    }
                    
                    syncSection(manager: manager)
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
        .navigationTitle("profile.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("profile.done".localized) {
                    dismiss()
                }
                .font(DesignTokens.Typography.secondarySemibold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            }
        }
        .toolbarBackground(DesignTokens.Colors.background1, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            manager.validateAvatar()
        }
        .alert("profile.sync.reset.title".localized, isPresented: $showResetConfirmation) {
            Button("profile.sync.reset.confirm".localized, role: .destructive) {
                Task { @MainActor [manager] in
                    isResettingProfile = true
                    await manager.resetProfileData()
                    isResettingProfile = false
                }
            }
            Button("profile.sync.reset.cancel".localized, role: .cancel) { }
        } message: {
            Text("profile.sync.reset.message".localized)
        }
        .onChange(of: avatarPickerItem) { previous, current in
            guard let item = current, previous != current else { return }
            Task { @MainActor [manager] in
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let fileExtension = item.supportedContentTypes.first?.preferredFilenameExtension ?? "dat"
                    await manager.updateAvatar(with: data, fileExtension: fileExtension)
                }
            }
        }
    }

    // MARK: - Profile Card
    private func profileCard(manager: ProfileManager) -> some View {
        let hasAvatar = avatarExists(for: manager)
        
        return VStack(spacing: DesignTokens.Spacing.xxl) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let image = avatarImage(for: manager) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: DesignTokens.Sizes.avatarSize,
                            height: DesignTokens.Sizes.avatarSize
                        )
                        .clipShape(Circle())
                        .shadow(
                            color: Color.black.opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                } else {
                    Circle()
                        .fill(DesignTokens.Colors.progressCard)
                        .frame(
                            width: DesignTokens.Sizes.avatarSize,
                            height: DesignTokens.Sizes.avatarSize
                        )
                        .overlay(
                            Image(systemName: manager.isSignedIn ? "person.crop.circle.fill" : "person.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        )
                        .shadow(
                            color: Color.black.opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                }
                
                // Edit button
                if manager.isSignedIn {
                    PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.cardBackground)
                                .frame(
                                    width: DesignTokens.Sizes.editButtonSize,
                                    height: DesignTokens.Sizes.editButtonSize
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            DesignTokens.Colors.borderSubtle,
                                            lineWidth: 1
                                        )
                                )
                                .shadow(
                                    color: Color.black.opacity(0.3),
                                    radius: 6,
                                    x: 0,
                                    y: 2
                                )
                            
                            Image(systemName: "pencil")
                                .font(.system(size: DesignTokens.Sizes.editIconSize))
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                        }
                    }
                }
            }
            
            // User name
            Text(manager.displayName)
                .font(DesignTokens.Typography.h1)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            // Action buttons
            VStack(spacing: DesignTokens.Spacing.sm) {
                if manager.isSignedIn {
                    if hasAvatar {
                        MinimalButton(
                            icon: "trash",
                            title: "profile.avatar.delete".localized,
                            foregroundColor: DesignTokens.Colors.textSecondary
                        ) {
                            Task { @MainActor [manager] in
                                await manager.deleteAvatar()
                            }
                        }
                    }
                    
                    MinimalButton(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "profile.signout".localized,
                        foregroundColor: DesignTokens.Colors.iconRed
                    ) {
                        manager.signOut()
                    }
                } else {
                    // Sign in with Apple button
                    SignInWithAppleButton(.signIn) { request in
                        manager.prepareSignInRequest(request)
                    } onCompletion: { result in
                        manager.handleSignInResult(result)
                    }
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                }
            }
        }
        .padding(DesignTokens.Spacing.xxxl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
                .fill(DesignTokens.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
                        .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 1)
                )
        )
        .shadow(
            color: DesignTokens.Shadows.card,
            radius: DesignTokens.Shadows.cardRadius,
            y: DesignTokens.Shadows.cardY
        )
    }
    
    // MARK: - Progress Section
    private func progressSection(progress: ProfileProgress) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
            Text("profile.progress.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
                    count: 2
                ),
                spacing: DesignTokens.Spacing.md
            ) {
                ProgressCardView(
                    icon: "questionmark.circle",
                    value: "\(progress.totalQuestionsAnswered)",
                    label: "profile.progress.questions".localized,
                    iconColor: DesignTokens.Colors.iconBlue
                )
                
                ProgressCardView(
                    icon: "checkmark.circle",
                    value: "\(progress.correctAnswers)",
                    label: "profile.progress.correct".localized,
                    iconColor: DesignTokens.Colors.iconGreen
                )
                
                ProgressCardView(
                    icon: "xmark.circle",
                    value: "\(progress.incorrectAnswers)",
                    label: "profile.progress.incorrect".localized,
                    iconColor: DesignTokens.Colors.iconRed
                )
                
                ProgressCardView(
                    icon: "exclamationmark.circle",
                    value: "\(progress.correctedMistakes)",
                    label: "profile.progress.corrected".localized,
                    iconColor: DesignTokens.Colors.iconOrange
                )
                
                ProgressCardView(
                    icon: "chart.bar",
                    value: "\(Int(progress.averageQuizScore))%",
                    label: "profile.progress.accuracy".localized,
                    iconColor: DesignTokens.Colors.iconPurple
                )
                
                ProgressCardView(
                    icon: "flame",
                    value: "\(progress.currentStreak)",
                    label: "profile.progress.streak".localized,
                    iconColor: DesignTokens.Colors.iconOrange
                )
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
                .fill(DesignTokens.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
                        .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 1)
                )
        )
        .shadow(
            color: DesignTokens.Shadows.card,
            radius: DesignTokens.Shadows.cardRadius,
            y: DesignTokens.Shadows.cardY
        )
    }
    
    // MARK: - Sync Section
    private func syncSection(manager: ProfileManager) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
            Text("profile.sync.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            // Sync status
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: syncIcon(for: manager.syncState))
                    .font(.system(size: DesignTokens.Sizes.iconSmall))
                    .foregroundColor(syncColor(for: manager.syncState))
                
                Text(syncMessage(for: manager))
                    .font(DesignTokens.Typography.secondaryRegular)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            
            if manager.isSignedIn {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    // Sync button
                    MinimalButton(
                        icon: "arrow.clockwise",
                        title: "profile.sync.refresh".localized,
                        foregroundColor: DesignTokens.Colors.iconBlue
                    ) {
                        Task { @MainActor [manager] in
                            await manager.refreshFromCloud(mergeStrategy: .newest)
                        }
                    }
                    .disabled(isResettingProfile || manager.isLoading)
                    .opacity((isResettingProfile || manager.isLoading) ? 0.6 : 1.0)
                    
                    // Reset button
                    MinimalButton(
                        icon: "trash",
                        title: "profile.sync.reset".localized,
                        foregroundColor: DesignTokens.Colors.iconRed
                    ) {
                        showResetConfirmation = true
                    }
                    .disabled(isResettingProfile || manager.isLoading)
                    .opacity((isResettingProfile || manager.isLoading) ? 0.6 : 1.0)
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
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
                .fill(DesignTokens.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
                        .stroke(DesignTokens.Colors.borderSubtle, lineWidth: 1)
                )
        )
        .shadow(
            color: DesignTokens.Shadows.card,
            radius: DesignTokens.Shadows.cardRadius,
            y: DesignTokens.Shadows.cardY
        )
    }
    
    // MARK: - Helpers
    private func syncIcon(for state: ProfileManager.SyncState) -> String {
        switch state {
        case .idle:
            return "checkmark.circle.fill"
        case .syncing:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private func syncColor(for state: ProfileManager.SyncState) -> Color {
        switch state {
        case .idle:
            return DesignTokens.Colors.statusGreen
        case .syncing:
            return DesignTokens.Colors.iconBlue
        case .failed:
            return DesignTokens.Colors.iconOrange
        }
    }

    private func syncMessage(for manager: ProfileManager) -> String {
        switch manager.syncState {
        case .idle:
            if let date = manager.profile.metadata.lastSyncedAt {
                let formatter = RelativeDateTimeFormatter()
                return String(
                    format: NSLocalizedString("profile.sync.lastSync", comment: "Last sync message"),
                    formatter.localizedString(for: date, relativeTo: Date())
                )
            }
            return NSLocalizedString("profile.sync.never", comment: "Never synced")
        case .syncing:
            return NSLocalizedString("profile.sync.inProgress", comment: "Sync in progress")
        case .failed(let message):
            return String(
                format: NSLocalizedString("profile.sync.failed", comment: "Sync failed message"),
                message
            )
        }
    }

    private func avatarExists(for manager: ProfileManager) -> Bool {
        guard let url = manager.profile.avatarURL else { return false }
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: url.path)
    }

    #if os(iOS)
    private func avatarImage(for manager: ProfileManager) -> Image? {
        guard let url = manager.profile.avatarURL,
              FileManager.default.fileExists(atPath: url.path),
              let uiImage = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
    #else
    private func avatarImage(for manager: ProfileManager) -> Image? {
        guard let url = manager.profile.avatarURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let nsImage = NSImage(data: data) else {
            return nil
        }
        return Image(nsImage: nsImage)
    }
    #endif
}

#Preview {
    let statsManager = StatsManager()
    let examStatsManager = ExamStatisticsManager()
    let adaptiveEngine = AdaptiveLearningEngine()
    let profileManager = ProfileManager(
        adaptiveEngine: adaptiveEngine,
        statsManager: statsManager,
        examStatisticsManager: examStatsManager
    )
    return NavigationStack {
        ProfileView()
    }
    .environment(\.profileManager, profileManager)
}
