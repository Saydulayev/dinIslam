//
//  ProfileBookmarksSectionView.swift
//  dinIslam
//
//  Сохранённые вопросы: сколько их, список и викторина по ним.
//

import SwiftUI

struct ProfileBookmarksSectionView: View {
    @Bindable var statsManager: StatsManager
    let onShowBookmarks: () -> Void
    let onStartBookmarksQuiz: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                Text("bookmarks.title".localized)
                    .font(DesignTokens.Typography.h2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                Text("\(statsManager.bookmarks.count)")
                    .font(DesignTokens.Typography.h2)
                    .foregroundStyle(DesignTokens.Colors.iconYellow)
            }
            .accessibilityElement(children: .combine)

            VStack(spacing: DesignTokens.Spacing.md) {
                MinimalButton(icon: "list.bullet", title: "bookmarks.showList".localized, action: onShowBookmarks)
                MinimalButton(icon: "star.fill", title: "bookmarks.startQuiz".localized, action: onStartBookmarksQuiz)
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
    }
}
