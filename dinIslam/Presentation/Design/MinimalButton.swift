//
//  MinimalButton.swift
//  dinIslam
//
//  Created by Saydulayev on 12.01.26.
//

import SwiftUI

/// Компактная кнопка-строка: иконка, подпись и шеврон на градиентной заливке роли
struct MinimalButton: View {
    let icon: String
    let title: String
    var role: DSButtonRole = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.Sizes.iconSmall))
                
                Text(title)
                    .font(DesignTokens.Typography.secondaryRegular)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: DesignTokens.Sizes.iconXSmall))
                    .opacity(0.7)
            }
        }
        .buttonStyle(DSButtonStyle(role: role, variant: .filled))
    }
}
