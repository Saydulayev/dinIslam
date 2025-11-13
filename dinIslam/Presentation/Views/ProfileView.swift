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
    @Environment(\.colorScheme) private var colorScheme
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var showResetConfirmation = false
    @State private var isResettingProfile = false

    var body: some View {
        @Bindable var manager = profileManager
        ScrollView {
            VStack(spacing: 0) {
                profileHeader(manager: manager)
                    .padding(.top, 8)
                
                if manager.isSignedIn {
                    progressSection(progress: manager.progress)
                        .padding(.top, 16)
                } else {
                    signInPromptView()
                        .padding(.top, 16)
                }
                
                syncSection(manager: manager)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("profile.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("profile.done".localized) {
                    dismiss()
                }
                .fontWeight(.medium)
            }
        }
        .onAppear {
            // Валидация аватара при открытии профиля
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
    }

    // MARK: - Sections
    private func signInPromptView() -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "icloud.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("profile.signin.prompt.title".localized)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("profile.signin.prompt.message".localized)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func profileHeader(manager: ProfileManager) -> some View {
        let hasAvatar = avatarExists(for: manager)

        return VStack(spacing: 24) {
            // Аватар
            ZStack {
                if let image = avatarImage(for: manager) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    Color.primary.opacity(colorScheme == .dark ? 0.15 : 0.1),
                                    lineWidth: 1
                                )
                        )
                } else {
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: manager.isSignedIn ? "person.crop.circle.fill" : "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Color(.tertiaryLabel))
                        )
                }
            }

            // Имя и email
            VStack(spacing: 4) {
                Text(manager.displayName)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                if let email = manager.email, !manager.isPrivateEmail(email) {
                    Text(email)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.secondary)
                }
            }

            // Кнопки действий
            VStack(spacing: 10) {
                if manager.isSignedIn {
                    PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: hasAvatar ? "photo" : "camera.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text(hasAvatar ? "profile.avatar.change".localized : "profile.avatar.select".localized)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(.primary)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if hasAvatar {
                        Button {
                            Task { @MainActor [manager] in
                                await manager.deleteAvatar()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .medium))
                                Text("profile.avatar.delete".localized)
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(.red)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Button {
                        manager.signOut()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                            Text("profile.signout".localized)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(.white)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        manager.prepareSignInRequest(request)
                    } onCompletion: { result in
                        manager.handleSignInResult(result)
                    }
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
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

    private func progressSection(progress: ProfileProgress) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("profile.progress.title".localized)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                metricView(
                    title: "profile.progress.questions".localized,
                    value: "\(progress.totalQuestionsAnswered)",
                    icon: "questionmark.circle.fill",
                    color: .blue
                )
                metricView(
                    title: "profile.progress.correct".localized,
                    value: "\(progress.correctAnswers)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                metricView(
                    title: "profile.progress.incorrect".localized,
                    value: "\(progress.incorrectAnswers)",
                    icon: "xmark.circle.fill",
                    color: .red
                )
                metricView(
                    title: "profile.progress.corrected".localized,
                    value: "\(progress.correctedMistakes)",
                    icon: "checkmark.circle.badge.xmark",
                    color: .orange
                )
                metricView(
                    title: "profile.progress.accuracy".localized,
                    value: "\(Int(progress.averageQuizScore))%",
                    icon: "chart.bar.fill",
                    color: .purple
                )
                metricView(
                    title: "profile.progress.streak".localized,
                    value: "\(progress.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func syncSection(manager: ProfileManager) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("profile.sync.title".localized)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 4)

            // Статус синхронизации
            HStack(spacing: 10) {
                Image(systemName: syncIcon(for: manager.syncState))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(syncColor(for: manager.syncState))
                Text(syncMessage(for: manager))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            if manager.isSignedIn {
                VStack(spacing: 10) {
                    Button {
                        Task { @MainActor [manager] in
                            await manager.refreshFromCloud(mergeStrategy: .newest)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                            Text("profile.sync.refresh".localized)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(.white)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isResettingProfile || manager.isLoading)
                    .opacity((isResettingProfile || manager.isLoading) ? 0.6 : 1.0)

                    Button {
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                            Text("profile.sync.reset".localized)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(.red)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isResettingProfile || manager.isLoading)
                    .opacity((isResettingProfile || manager.isLoading) ? 0.6 : 1.0)
                }
            } else {
                // Информационное сообщение для неавторизованных пользователей
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("profile.sync.signin.required".localized)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }

            if isResettingProfile {
                HStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("profile.sync.reset.inProgress".localized)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Helpers
    private func metricView(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 20)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 110)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }

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
            return .green
        case .syncing:
            return .blue
        case .failed:
            return .orange
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

