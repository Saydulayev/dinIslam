//
//  ProfileView.swift
//  dinIslam
//
//  Created by GPT-5 Codex on 09.11.25.
//

import AuthenticationServices
import Observation
import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.profileManager) private var profileManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        @Bindable var manager = profileManager
        ScrollView {
            VStack(spacing: 24) {
                profileHeader(manager: manager)
                progressSection(progress: manager.progress)
                examSection(progress: manager.progress)
                recommendationsSection(recommendations: manager.recommendations)
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
    }

    // MARK: - Sections
    private func profileHeader(manager: ProfileManager) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                    .shadow(color: .blue.opacity(0.2), radius: 12, x: 0, y: 6)
                Image(systemName: manager.isSignedIn ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
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

    private func recommendationsSection(recommendations: [LearningRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("profile.recommendations.title".localized)
                .font(.headline)

            if recommendations.isEmpty {
                Text("profile.recommendations.empty".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.tertiarySystemBackground))
                    )
            } else {
                ForEach(recommendations) { recommendation in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recommendation.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(recommendation.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let topicId = recommendation.topicId {
                            Text("profile.recommendations.topic".localized(arguments: topicId))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
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
                Button {
                    Task {
                        await manager.refreshFromCloud(mergeStrategy: .newest)
                    }
                } label: {
                    Label("profile.sync.refresh".localized, systemImage: "arrow.clockwise.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
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

