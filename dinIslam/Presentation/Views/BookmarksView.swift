//
//  BookmarksView.swift
//  dinIslam
//
//  Сохранённые вопросы: вопрос, правильный ответ и тема; викторина по сохранённым.
//  Снятый вопрос остаётся в списке до ухода с экрана — промах можно исправить, нажав звёздочку снова.
//

import SwiftUI

struct BookmarksView: View {
    @Bindable var statsManager: StatsManager
    let loadQuestions: () async throws -> [Question]
    let onStartQuiz: () -> Void

    private enum LoadState {
        case loading
        case loaded([Question])
        case failed
    }

    @State private var loadState = LoadState.loading

    var body: some View {
        ZStack {
            AppBackground()

            switch loadState {
            case .loading:
                ProgressView()
                    .tint(DesignTokens.Colors.textPrimary)
            case .loaded(let questions):
                if questions.isEmpty {
                    ContentUnavailableView(
                        "bookmarks.emptyTitle".localized,
                        systemImage: "star",
                        description: Text("bookmarks.emptyHint".localized)
                    )
                } else {
                    list(questions)
                }
            case .failed:
                ContentUnavailableView {
                    Label("bookmarks.loadError".localized, systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("exam.error.retry".localized, action: retry)
                        .buttonStyle(DSButtonStyle())
                }
            }
        }
        .navigationTitle("bookmarks.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await load()
        }
    }

    private func list(_ questions: [Question]) -> some View {
        let savedCount = questions.filter { statsManager.isBookmarked($0.id) }.count
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                GradientActionButton(
                    icon: "star.fill",
                    title: "bookmarks.startQuiz".localized,
                    subtitle: "bookmarks.count".localized(count: savedCount, arguments: savedCount),
                    gradient: [DesignTokens.Colors.blueGradientStart, DesignTokens.Colors.blueGradientEnd],
                    action: onStartQuiz
                )
                .disabled(savedCount == 0)
                .opacity(savedCount == 0 ? 0.5 : 1)
                .padding(.bottom, DesignTokens.Spacing.xs)

                ForEach(questions) { question in
                    BookmarkRow(question: question, isBookmarked: statsManager.isBookmarked(question.id)) {
                        statsManager.toggleBookmark(question.id)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.top, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxxl)
        }
    }

    private func retry() {
        Task { await load() }
    }

    private func load() async {
        if case .failed = loadState {
            loadState = .loading
        }
        do {
            // Состав списка фиксируется при показе экрана, звёздочки — по текущим закладкам
            let allQuestions = try await loadQuestions()
            loadState = .loaded(statsManager.getBookmarkedQuestions(from: allQuestions))
        } catch is CancellationError {
            return
        } catch {
            AppLogger.error("Failed to load bookmarked questions", error: error, category: AppLogger.data)
            loadState = .failed
        }
    }
}

private struct BookmarkRow: View {
    let question: Question
    let isBookmarked: Bool
    let onToggle: () -> Void

    private var correctAnswer: String? {
        question.answers.indices.contains(question.correctIndex) ? question.answers[question.correctIndex].text : nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(question.text)
                    .font(DesignTokens.Typography.bodyRegular)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let correctAnswer {
                    Label(correctAnswer, systemImage: "checkmark.circle.fill")
                        .font(DesignTokens.Typography.secondaryRegular)
                        .foregroundStyle(DesignTokens.Colors.success)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if question.category != QuestionCategory.generalId {
                    Label(
                        QuestionCategory.displayName(for: question.category),
                        systemImage: QuestionCategory.icon(for: question.category)
                    )
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button(action: onToggle) {
                Image(systemName: isBookmarked ? "star.fill" : "star")
                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                    .foregroundStyle(isBookmarked ? DesignTokens.Colors.iconYellow : DesignTokens.Colors.textTertiary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel((isBookmarked ? "bookmarks.remove" : "bookmarks.add").localized)
        }
        .padding(DesignTokens.Spacing.lg)
        .glowBorder()
        .opacity(isBookmarked ? 1 : 0.6)
    }
}

#Preview {
    NavigationStack {
        BookmarksView(
            statsManager: StatsManager(),
            loadQuestions: { [] },
            onStartQuiz: {}
        )
    }
}
