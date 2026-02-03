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
    @Binding var avatarPickerItem: PhotosPickerItem?
    @Binding var isEditingDisplayName: Bool
    @Binding var editingDisplayName: String
    
    let hasAvatar: Bool
    
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
                    }
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
                    }
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
                        manager.signOut()
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
    
    private func saveDisplayName() {
        let trimmedName = editingDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { @MainActor [manager] in
            await manager.updateDisplayName(trimmedName.isEmpty ? nil : trimmedName)
            isEditingDisplayName = false
        }
    }
}

