//
//  TermsOfServiceView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("terms.title".localized)
                            .font(DesignTokens.Typography.h1)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text("terms.lastUpdated".localized)
                            .font(DesignTokens.Typography.label)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .padding(.bottom, DesignTokens.Spacing.md)
                    
                    // Acceptance
                    TermsSectionView(
                        title: "terms.acceptance.title".localized,
                        content: "terms.acceptance.content".localized
                    )
                    
                    // License
                    TermsSectionView(
                        title: "terms.license.title".localized,
                        content: "terms.license.content".localized
                    )
                    
                    // Prohibited Uses
                    TermsSectionView(
                        title: "terms.prohibited.title".localized,
                        content: "terms.prohibited.content".localized
                    )
                    
                    // User Content
                    TermsSectionView(
                        title: "terms.content.title".localized,
                        content: "terms.content.content".localized
                    )
                    
                    // Termination
                    TermsSectionView(
                        title: "terms.termination.title".localized,
                        content: "terms.termination.content".localized
                    )
                    
                    // Disclaimer
                    TermsSectionView(
                        title: "terms.disclaimer.title".localized,
                        content: "terms.disclaimer.content".localized
                    )
                    
                    // Limitation of Liability
                    TermsSectionView(
                        title: "terms.liability.title".localized,
                        content: "terms.liability.content".localized
                    )
                    
                    // Governing Law
                    TermsSectionView(
                        title: "terms.law.title".localized,
                        content: "terms.law.content".localized
                    )
                    
                    // Contact Information
                    TermsSectionView(
                        title: "terms.contact.title".localized,
                        content: "terms.contact.content".localized
                    )
                }
                .padding(DesignTokens.Spacing.xxl)
            }
        }
        .navigationTitle("terms.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("terms.done".localized) {
                    dismiss()
                }
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Section View
struct TermsSectionView: View {
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
        .glowBorder(cornerRadius: DesignTokens.CornerRadius.large)
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
