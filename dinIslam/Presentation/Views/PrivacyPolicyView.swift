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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("privacy.title".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("privacy.lastUpdated".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                
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
            .padding()
        }
        .navigationTitle("privacy.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("privacy.done".localized) {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

struct SectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .lineSpacing(4)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
