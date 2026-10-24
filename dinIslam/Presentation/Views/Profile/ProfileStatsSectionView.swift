//
//  ProfileStatsSectionView.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import SwiftUI

struct ProfileStatsSectionView: View {
    @Environment(\.questionPoolProgressManager) private var questionPoolProgressManager
    @Bindable var manager: ProfileManager
    @Bindable var statsManager: StatsManager
    /// id вопросов текущего банка; nil, пока вопросы загружаются — вместо «0 / 0» показываем прочерк
    let questionIds: Set<String>?
    let isResettingProfile: Bool
    let statsRefreshTrigger: Int
    @State private var studiedCount: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
            Text("profile.progress.title".localized)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            // Grid, а не LazyVGrid: карточки в ряду одной высоты при крупном шрифте
            Grid(
                horizontalSpacing: DesignTokens.Spacing.md,
                verticalSpacing: DesignTokens.Spacing.md
            ) {
                GridRow {
                    // Questions Studied
                    ProgressCardView(
                        icon: "questionmark.circle",
                        value: questionIds.map { "\(studiedCount) / \($0.count)" } ?? "—",
                        label: "stats.questionsStudied.title".localized,
                        iconColor: DesignTokens.Colors.iconBlue,
                        backgroundColor: DesignTokens.Colors.iconBlue.opacity(0.2)
                    )
                    
                    // Correct Answers
                    ProgressCardView(
                        icon: "checkmark.circle",
                        value: "\(statsManager.stats.correctAnswers)",
                        label: "stats.correctAnswers.title".localized,
                        iconColor: DesignTokens.Colors.iconGreen,
                        backgroundColor: DesignTokens.Colors.iconGreen.opacity(0.2)
                    )
                }
                
                GridRow {
                    // Incorrect Answers
                    ProgressCardView(
                        icon: "xmark.circle",
                        value: "\(statsManager.stats.incorrectAnswers)",
                        label: "stats.incorrectAnswers.title".localized,
                        iconColor: DesignTokens.Colors.iconRed,
                        backgroundColor: DesignTokens.Colors.iconRed.opacity(0.2)
                    )
                    
                    // Corrected Mistakes
                    ProgressCardView(
                        icon: "exclamationmark.circle",
                        value: "\(statsManager.stats.correctedMistakes)",
                        label: "stats.correctedMistakes.title".localized,
                        iconColor: DesignTokens.Colors.iconYellow,
                        backgroundColor: DesignTokens.Colors.iconYellow.opacity(0.2)
                    )
                }
                
                GridRow {
                    // Accuracy
                    ProgressCardView(
                        icon: "chart.bar",
                        value: statsManager.stats.accuracyPercentage.displayScore,
                        label: "profile.progress.accuracy".localized,
                        iconColor: DesignTokens.Colors.iconPurple,
                        backgroundColor: DesignTokens.Colors.iconPurple.opacity(0.2)
                    )
                    
                    // Серия дней с занятиями, как на главном экране
                    ProgressCardView(
                        icon: "flame",
                        value: "\(statsManager.dayStreak)",
                        label: "profile.progress.streak".localized,
                        iconColor: DesignTokens.Colors.iconFlame,
                        backgroundColor: DesignTokens.Colors.iconFlame.opacity(0.2)
                    )
                }
            }
            
            // Horizontal "Total Questions" card
            HStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "book.closed")
                    .font(.system(size: DesignTokens.Sizes.iconMedium))
                    .foregroundStyle(.white) // Белая иконка для лучшей видимости на градиенте
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("stats.totalQuestions.title".localized)
                        .font(DesignTokens.Typography.label)
                        .foregroundStyle(.white.opacity(0.9)) // Белый текст с небольшой прозрачностью
                    
                    Text(questionIds.map { String($0.count) } ?? "—")
                        .font(DesignTokens.Typography.statsValue)
                        .foregroundStyle(.white) // Белый текст для лучшей читаемости
                }
                
                Spacer()
            }
            .padding(DesignTokens.Spacing.lg)
            .background(
                ZStack {
                    // Градиентный фон (как у карточек)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            DesignTokens.Colors.purpleGradientStart,
                            DesignTokens.Colors.purpleGradientEnd
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Рамка с градиентом и свечением
                    GlowBorder()
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            .shadow(
                color: DesignTokens.Colors.purpleGradientStart.opacity(0.5),
                radius: 12,
                y: 6
            )
        }
        .padding(DesignTokens.Spacing.xxl)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
        .onAppear {
            loadProgressStats()
        }
        .onChange(of: questionIds) { _, _ in
            loadProgressStats()
        }
        .onChange(of: isResettingProfile) { _, newValue in
            // Когда сброс завершён (isResettingProfile становится false), обновляем статистику
            if !newValue {
                loadProgressStats()
            }
        }
        .onChange(of: statsRefreshTrigger) { _, _ in
            // Обновляем статистику при изменении триггера (например, после сброса)
            loadProgressStats()
        }
        .onChange(of: manager.profile.metadata.lastSyncedAt) { _, _ in
            // Пройденные вопросы могли прийти с другого устройства
            loadProgressStats()
        }
    }
    
    private func loadProgressStats() {
        guard let questionIds else { return }
        // Только вопросы текущего банка: id удалённых вопросов не увеличивают «Изучено»
        let stats = questionPoolProgressManager.getProgressStats(total: questionIds.count, currentQuestionIds: questionIds, version: 1)
        studiedCount = stats.used
    }
}

