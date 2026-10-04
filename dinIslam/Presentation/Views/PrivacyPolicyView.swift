//
//  PrivacyPolicyView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("privacy.title".localized)
                            .font(DesignTokens.Typography.h1)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        
                        Text("privacy.lastUpdated".localized)
                            .font(DesignTokens.Typography.label)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    .padding(.bottom, DesignTokens.Spacing.md)
                    
                    // Introduction
                    SectionView(
                        title: "privacy.introduction.title".localized,
                        content: "privacy.introduction.content".localized
                    )
                    
                    // Information Collection
                    SectionView(
                        title: "privacy.collection.title".localized,
                        content: "privacy.collection.content".localized
                    )
                    
                    // Data Usage
                    SectionView(
                        title: "privacy.usage.title".localized,
                        content: "privacy.usage.content".localized
                    )
                    
                    // Data Storage
                    SectionView(
                        title: "privacy.storage.title".localized,
                        content: "privacy.storage.content".localized
                    )
                    
                    // Third Party Services
                    SectionView(
                        title: "privacy.thirdParty.title".localized,
                        content: "privacy.thirdParty.content".localized
                    )
                    
                    // User Rights
                    SectionView(
                        title: "privacy.rights.title".localized,
                        content: "privacy.rights.content".localized
                    )
                    
                    // Contact Information
                    SectionView(
                        title: "privacy.contact.title".localized,
                        content: "privacy.contact.content".localized
                    )
                    
                    // Changes to Policy
                    SectionView(
                        title: "privacy.changes.title".localized,
                        content: "privacy.changes.content".localized
                    )
                }
                .padding(DesignTokens.Spacing.xxl)
            }
        }
        .navigationTitle("privacy.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("privacy.done".localized) {
                    dismiss()
                }
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .fontWeight(.semibold)
            }
        }
    }
}

struct SectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(title)
                .font(DesignTokens.Typography.h2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            
            Text(content)
                .font(DesignTokens.Typography.bodyRegular)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.xxl)
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.large)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
