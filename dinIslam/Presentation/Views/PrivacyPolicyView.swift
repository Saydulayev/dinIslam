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
            // Background - очень темный градиент с оттенками индиго/фиолетового (как на главном экране)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#0a0a1a"), // темно-индиго сверху
                    Color(hex: "#000000") // черный снизу
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("privacy.title".localized)
                            .font(DesignTokens.Typography.h1)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text("privacy.lastUpdated".localized)
                            .font(DesignTokens.Typography.label)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
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
        .toolbarBackground(.clear, for: .navigationBar) // прозрачный toolbar для градиента
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("privacy.done".localized) {
                    dismiss()
                }
                .foregroundColor(DesignTokens.Colors.textPrimary)
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
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(content)
                .font(DesignTokens.Typography.bodyRegular)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.xxl)
        .background(
            // Прозрачная рамка с фиолетовым свечением (как на главном экране)
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
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
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
