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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("terms.title".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("terms.lastUpdated".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                
                // Acceptance
                SectionView(
                    title: "terms.acceptance.title".localized,
                    content: "terms.acceptance.content".localized
                )
                
                // License
                SectionView(
                    title: "terms.license.title".localized,
                    content: "terms.license.content".localized
                )
                
                // Prohibited Uses
                SectionView(
                    title: "terms.prohibited.title".localized,
                    content: "terms.prohibited.content".localized
                )
                
                // User Content
                SectionView(
                    title: "terms.content.title".localized,
                    content: "terms.content.content".localized
                )
                
                // Termination
                SectionView(
                    title: "terms.termination.title".localized,
                    content: "terms.termination.content".localized
                )
                
                // Disclaimer
                SectionView(
                    title: "terms.disclaimer.title".localized,
                    content: "terms.disclaimer.content".localized
                )
                
                // Limitation of Liability
                SectionView(
                    title: "terms.liability.title".localized,
                    content: "terms.liability.content".localized
                )
                
                // Governing Law
                SectionView(
                    title: "terms.law.title".localized,
                    content: "terms.law.content".localized
                )
                
                // Contact Information
                SectionView(
                    title: "terms.contact.title".localized,
                    content: "terms.contact.content".localized
                )
            }
            .padding()
        }
        .navigationTitle("terms.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("terms.done".localized) {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
