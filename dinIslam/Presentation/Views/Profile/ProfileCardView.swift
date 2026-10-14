//
//  ProfileCardView.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import PhotosUI
import SwiftUI

struct ProfileCardView: View {
    @Bindable var manager: ProfileManager
    @Binding var avatarPickerItem: PhotosPickerItem?
    @Binding var isEditingDisplayName: Bool
    @Binding var editingDisplayName: String
    
    let hasAvatar: Bool
    
    /// Фото читается с диска в фоне, а не в body при каждой перерисовке
    @State private var avatarImage: Image?
    @State private var showingDeleteAllDataConfirmation = false
    @State private var isDeletingAllData = false
    @State private var showingDeleteAllDataError = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let image = avatarImage {
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
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: DesignTokens.Sizes.iconDisplay))
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
            // Файл перезаписывается по тому же пути, поэтому ключ включает дату изменения профиля
            .task(id: AvatarKey(url: manager.profile.avatarURL, updatedAt: manager.profile.metadata.updatedAt)) {
                avatarImage = await ProfileViewHelpers.loadAvatarImage(from: manager.profile.avatarURL)
            }
            
            // User name with edit functionality
            VStack(spacing: DesignTokens.Spacing.xs) {
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
                
                    Button(action: {
                        if isEditingDisplayName {
                            saveDisplayName()
                        } else {
                            let name = manager.editableDisplayName
                            editingDisplayName = String(name.prefix(DesignTokens.Limits.maxDisplayNameLength))
                            isEditingDisplayName = true
                        }
                    }) {
                        Image(systemName: isEditingDisplayName ? "checkmark" : "pencil")
                            .font(.system(size: DesignTokens.Sizes.iconSmall))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(
                        (isEditingDisplayName ? "accessibility.displayName.save" : "accessibility.displayName.edit").localized
                    )
                }
                
                if manager.needsDisplayName && !isEditingDisplayName {
                    Text("profile.noName.hint".localized)
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Action buttons
            VStack(spacing: DesignTokens.Spacing.sm) {
                if hasAvatar {
                    MinimalButton(
                        icon: "trash",
                        title: "profile.avatar.delete".localized,
                        role: .secondary
                    ) {
                        Task { @MainActor [manager] in
                            await manager.deleteAvatar()
                        }
                    }
                }
                
                MinimalButton(
                    icon: "person.crop.circle.badge.xmark",
                    title: "profile.deleteAllData".localized,
                    role: .destructive
                ) {
                    showingDeleteAllDataConfirmation = true
                }
                .disabled(manager.isLoading)
                
                if isDeletingAllData {
                    ProgressView()
                        .tint(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.xxxl)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
        .alert(
            "profile.deleteAllData.confirm.title".localized,
            isPresented: $showingDeleteAllDataConfirmation
        ) {
            Button("profile.deleteAllData.confirm.ok".localized, role: .destructive) {
                deleteAllData()
            }
            Button("profile.deleteAllData.confirm.cancel".localized, role: .cancel) { }
        } message: {
            Text("profile.deleteAllData.confirm.message".localized)
        }
        .alert(
            "profile.deleteAllData.error.title".localized,
            isPresented: $showingDeleteAllDataError
        ) {
            Button("profile.deleteAllData.error.ok".localized, role: .cancel) { }
        } message: {
            Text("profile.deleteAllData.error.message".localized)
        }
    }
    
    private struct AvatarKey: Equatable {
        let url: URL?
        let updatedAt: Date
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
    
    private func deleteAllData() {
        Task { @MainActor [manager] in
            isDeletingAllData = true
            defer { isDeletingAllData = false }
            do {
                try await manager.deleteAllData()
            } catch {
                AppLogger.error("Failed to delete all data", error: error, category: AppLogger.data)
                showingDeleteAllDataError = true
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

