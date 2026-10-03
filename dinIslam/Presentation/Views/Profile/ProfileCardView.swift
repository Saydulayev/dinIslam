//
//  ProfileCardView.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import AuthenticationServices
import PhotosUI
import SwiftUI

struct ProfileCardView: View {
    @Bindable var manager: ProfileManager
    @Environment(\.achievementManager) private var achievementManager: AchievementManager
    @Binding var avatarPickerItem: PhotosPickerItem?
    @Binding var isEditingDisplayName: Bool
    @Binding var editingDisplayName: String
    
    let hasAvatar: Bool
    
    @State private var showingSignOutConfirmation = false
    @State private var showingDeleteAccountConfirmation = false
    @State private var isDeletingAccount = false
    @State private var showingDeleteAccountError = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let image = ProfileViewHelpers.avatarImage(for: manager) {
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
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                    }
                    .accessibilityLabel("profile.avatar.change".localized)
                }
            }
            
            // User name with edit functionality
            HStack(spacing: DesignTokens.Spacing.sm) {
                if isEditingDisplayName {
                    TextField("profile.displayName.placeholder".localized, text: displayNameBinding)
                        .font(DesignTokens.Typography.h1)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .onSubmit {
                            saveDisplayName()
                        }
                } else {
                    Text(manager.displayName)
                        .font(DesignTokens.Typography.h1)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }
                
                if manager.isSignedIn {
                    Button(action: {
                        if isEditingDisplayName {
                            saveDisplayName()
                        } else {
                            let name = manager.profile.customDisplayName ?? manager.displayName
                            editingDisplayName = String(name.prefix(DesignTokens.Limits.maxDisplayNameLength))
                            isEditingDisplayName = true
                        }
                    }) {
                        Image(systemName: isEditingDisplayName ? "checkmark" : "pencil")
                            .font(.system(size: DesignTokens.Sizes.iconSmall))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(
                        (isEditingDisplayName ? "accessibility.displayName.save" : "accessibility.displayName.edit").localized
                    )
                }
            }
            
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
                        showingSignOutConfirmation = true
                    }
                    .disabled(manager.isLoading)
                    
                    MinimalButton(
                        icon: "person.crop.circle.badge.xmark",
                        title: "profile.deleteAccount".localized,
                        foregroundColor: DesignTokens.Colors.iconRed
                    ) {
                        showingDeleteAccountConfirmation = true
                    }
                    .disabled(manager.isLoading)
                    
                    if isDeletingAccount {
                        ProgressView()
                            .tint(DesignTokens.Colors.textSecondary)
                    }
                } else {
                    // Sign in with Apple button в стиле главного экрана
                    SignInWithAppleButton(.signIn) { request in
                        manager.prepareSignInRequest(request)
                    } onCompletion: { result in
                        manager.handleSignInResult(result)
                    }
                    .frame(height: 50)
                    .overlay(
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
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                }
            }
        }
        .padding(DesignTokens.Spacing.xxxl)
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
        .alert(
            "profile.signout.confirm.title".localized,
            isPresented: $showingSignOutConfirmation
        ) {
            Button("profile.signout.confirm.ok".localized, role: .destructive) {
                manager.signOut()
            }
            Button("profile.signout.confirm.cancel".localized, role: .cancel) { }
        } message: {
            Text("profile.signout.confirm.message".localized)
        }
        .alert(
            "profile.deleteAccount.confirm.title".localized,
            isPresented: $showingDeleteAccountConfirmation
        ) {
            Button("profile.deleteAccount.confirm.ok".localized, role: .destructive) {
                deleteAccount()
            }
            Button("profile.deleteAccount.confirm.cancel".localized, role: .cancel) { }
        } message: {
            Text("profile.deleteAccount.confirm.message".localized)
        }
        .alert(
            "profile.deleteAccount.error.title".localized,
            isPresented: $showingDeleteAccountError
        ) {
            Button("profile.deleteAccount.error.ok".localized, role: .cancel) { }
        } message: {
            Text("profile.deleteAccount.error.message".localized)
        }
    }
    
    private var displayNameBinding: Binding<String> {
        Binding(
            get: { editingDisplayName },
            set: { newValue in
                let maxLen = DesignTokens.Limits.maxDisplayNameLength
                editingDisplayName = String(newValue.prefix(maxLen))
            }
        )
    }
    
    private func deleteAccount() {
        Task { @MainActor [manager, achievementManager] in
            isDeletingAccount = true
            defer { isDeletingAccount = false }
            do {
                try await manager.deleteAccount()
                achievementManager.resetAllAchievements()
            } catch {
                AppLogger.error("Failed to delete account", error: error, category: AppLogger.data)
                showingDeleteAccountError = true
            }
        }
    }
    
    private func saveDisplayName() {
        let trimmedName = editingDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { @MainActor [manager] in
            await manager.updateDisplayName(trimmedName.isEmpty ? nil : trimmedName)
            isEditingDisplayName = false
        }
    }
}

