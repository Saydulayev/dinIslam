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
            VStack(spacing: 24) {
                profileHeader(manager: manager)
                progressSection(progress: manager.progress)
                examSection(progress: manager.progress)
                syncSection(manager: manager)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("profile.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("profile.done".localized) {
                    dismiss()
                }
            }
        }
        .onAppear {
            // Валидация аватара при открытии профиля
            manager.validateAvatar()
        }
        .alert("profile.sync.reset.title".localized, isPresented: $showResetConfirmation) {
            Button("profile.sync.reset.confirm".localized, role: .destructive) {
                Task {
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
    private func profileHeader(manager: ProfileManager) -> some View {
        let hasAvatar = avatarExists(for: manager)

        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 132, height: 132)
                    .shadow(color: .blue.opacity(0.2), radius: 12, x: 0, y: 6)
                if let image = avatarImage(for: manager) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.2 : 0.6), lineWidth: 2)
                        )
                        .shadow(radius: 4)
                } else {
                    Image(systemName: manager.isSignedIn ? "person.crop.circle.badge.plus" : "person.crop.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            VStack(spacing: 6) {
                Text(manager.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let email = manager.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 12) {
                if manager.isSignedIn {
                    PhotosPicker(selection: $avatarPickerItem, matching: .images) {
                        Label(
                            hasAvatar ? "profile.avatar.change".localized : "profile.avatar.select".localized,
                            systemImage: "camera.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    if hasAvatar {
                        Button(role: .destructive) {
                            Task {
                                await manager.deleteAvatar()
                            }
                        } label: {
                            Label("profile.avatar.delete".localized, systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    Button(role: .destructive) {
                        manager.signOut()
                    } label: {
                        Label("profile.signout".localized, systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
        .onChange(of: avatarPickerItem) { previous, current in
            guard let item = current, previous != current else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let fileExtension = item.supportedContentTypes.first?.preferredFilenameExtension ?? "dat"
                    await manager.updateAvatar(with: data, fileExtension: fileExtension)
                }
            }
        }
    }

    private func progressSection(progress: ProfileProgress) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("profile.progress.title".localized)
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                metricView(title: "profile.progress.questions".localized, value: "\(progress.totalQuestionsAnswered)")
                metricView(title: "profile.progress.correct".localized, value: "\(progress.correctAnswers)")
                metricView(title: "profile.progress.accuracy".localized, value: "\(Int(progress.averageQuizScore))%")
                metricView(title: "profile.progress.streak".localized, value: "\(progress.currentStreak) 🔥")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func examSection(progress: ProfileProgress) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("profile.exams.title".localized)
                .font(.headline)

            HStack(spacing: 12) {
                metricView(title: "profile.exams.completed".localized, value: "\(progress.examsTaken)")
                metricView(title: "profile.exams.passed".localized, value: "\(progress.examsPassed)")
                let passRate = progress.examsTaken > 0 ? Int(Double(progress.examsPassed) / Double(progress.examsTaken) * 100) : 0
                metricView(title: "profile.exams.passRate".localized, value: "\(passRate)%")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func syncSection(manager: ProfileManager) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("profile.sync.title".localized)
                .font(.headline)

            HStack {
                Image(systemName: syncIcon(for: manager.syncState))
                    .foregroundColor(syncColor(for: manager.syncState))
                Text(syncMessage(for: manager))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if manager.isSignedIn {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        Task {
                            await manager.refreshFromCloud(mergeStrategy: .newest)
                        }
                    } label: {
                        Label("profile.sync.refresh".localized, systemImage: "arrow.clockwise.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isResettingProfile || manager.isLoading)

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("profile.sync.reset".localized, systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isResettingProfile || manager.isLoading)
                }
            }

            if isResettingProfile {
                ProgressView("profile.sync.reset.inProgress".localized)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Helpers
    private func metricView(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
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

