//
//  TopicsView.swift
//  dinIslam
//
//  Выбор темы для викторины: сколько вопросов темы изучено и насколько точны ответы.
//

import SwiftUI

struct TopicsView: View {
    @Bindable var statsManager: StatsManager
    let loadTopics: () async throws -> [TopicBankProgress]
    let onSelectTopic: (QuestionCategory) -> Void

    private enum LoadState {
        case loading
        case loaded([TopicBankProgress])
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
            case .loaded(let topics):
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("topics.caption".localized(arguments: QuizUseCase.topicSessionSize))
                            .font(DesignTokens.Typography.secondaryRegular)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, DesignTokens.Spacing.xs)

                        ForEach(topics) { topic in
                            TopicPickerRow(
                                topic: topic,
                                stat: statsManager.stats.topicStats[topic.category.rawValue]
                            ) {
                                onSelectTopic(topic.category)
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    .padding(.top, DesignTokens.Spacing.lg)
                    .padding(.bottom, DesignTokens.Spacing.xxxl)
                }
            case .failed:
                ContentUnavailableView {
                    Label("topics.loadError".localized, systemImage: "exclamationmark.triangle")
                } actions: {
                    Button("exam.error.retry".localized, action: retry)
                        .buttonStyle(DSButtonStyle())
                }
            }
        }
        .navigationTitle("topics.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        // Прогресс перечитывается при каждом показе: после викторины по теме изучено больше
        .task {
            await load()
        }
    }

    private func retry() {
        Task { await load() }
    }

    private func load() async {
        // При обновлении показываем уже загруженный список, а не индикатор загрузки
        if case .failed = loadState {
            loadState = .loading
        }
        do {
            let topics = try await loadTopics()
            loadState = topics.isEmpty ? .failed : .loaded(topics)
        } catch is CancellationError {
            return
        } catch {
            AppLogger.error("Failed to load topics progress", error: error, category: AppLogger.data)
            loadState = .failed
        }
    }
}

#Preview {
    NavigationStack {
        TopicsView(
            statsManager: StatsManager(),
            loadTopics: {
                [
                    TopicBankProgress(category: .aqida, progress: BankProgress(studied: 40, total: 129)),
                    TopicBankProgress(category: .fiqh, progress: BankProgress(studied: 98, total: 98))
                ]
            },
            onSelectTopic: { _ in }
        )
    }
}
