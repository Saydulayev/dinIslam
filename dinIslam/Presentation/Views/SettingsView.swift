//
//  SettingsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationManager) private var notificationManager: NotificationManager
    @State private var showingNotificationSettings = false
    
    init(viewModel: SettingsViewModel) {
        _viewModel = Bindable(viewModel)
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    DesignTokens.Colors.background1,
                    DesignTokens.Colors.background2
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxxl) {
                    // MARK: - App Settings Section
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("settings.appSettings".localized)
                            .font(DesignTokens.Typography.h2)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            // Language Setting
                            SettingRow(
                                icon: "globe",
                                iconColor: DesignTokens.Colors.iconBlue,
                                title: "settings.language.title".localized,
                                subtitle: viewModel.settings.language.displayName,
                                showChevron: false
                            ) {
                                viewModel.showingLanguagePicker = true
                            }
                            
                            Divider()
                                .background(DesignTokens.Colors.borderSubtle)
                            
                            // Sound Setting
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundColor(DesignTokens.Colors.iconGreen)
                                    .frame(width: DesignTokens.Sizes.iconLarge)
                                
                                Text("settings.sound.title".localized)
                                    .font(DesignTokens.Typography.bodyRegular)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { viewModel.settings.soundEnabled },
                                    set: { viewModel.updateSoundEnabled($0) }
                                ))
                                .tint(DesignTokens.Colors.iconGreen)
                            }
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            
                            Divider()
                                .background(DesignTokens.Colors.borderSubtle)
                            
                            // Haptic Feedback Setting
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .foregroundColor(DesignTokens.Colors.iconOrange)
                                    .frame(width: DesignTokens.Sizes.iconLarge)
                                
                                Text("settings.haptic.title".localized)
                                    .font(DesignTokens.Typography.bodyRegular)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { viewModel.settings.hapticEnabled },
                                    set: { viewModel.updateHapticEnabled($0) }
                                ))
                                .tint(DesignTokens.Colors.iconOrange)
                            }
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            
                            Divider()
                                .background(DesignTokens.Colors.borderSubtle)
                            
                            // Notifications Setting
                            SettingRow(
                                icon: "bell",
                                iconColor: DesignTokens.Colors.iconPurple,
                                title: "settings.notifications.title".localized,
                                subtitle: nil,
                                showChevron: false
                            ) {
                                showingNotificationSettings = true
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.xxl)
                    .cardStyle(
                        cornerRadius: DesignTokens.CornerRadius.xlarge,
                        fillColor: DesignTokens.Colors.cardBackground,
                        borderColor: DesignTokens.Colors.iconBlue.opacity(0.3),
                        shadowColor: Color.black.opacity(0.2),
                        shadowRadius: 8,
                        shadowYOffset: 4
                    )
                    
                    // MARK: - Support Section
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("settings.support".localized)
                            .font(DesignTokens.Typography.h2)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            // Send Feedback
                            SettingRow(
                                icon: "envelope",
                                iconColor: DesignTokens.Colors.iconBlue,
                                title: "settings.feedback.title".localized,
                                subtitle: "settings.feedback.subtitle".localized,
                                showChevron: false
                            ) {
                                if let url = URL(string: "mailto:saydulayev.wien@gmail.com?subject=Feedback&body=") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            Divider()
                                .background(DesignTokens.Colors.borderSubtle)
                            
                            // Rate App
                            SettingRow(
                                icon: "star",
                                iconColor: .yellow,
                                title: "settings.rate.title".localized,
                                subtitle: "settings.rate.subtitle".localized,
                                showChevron: false
                            ) {
                                viewModel.requestAppReview()
                            }
                            
                            Divider()
                                .background(DesignTokens.Colors.borderSubtle)
                            
                            // Share App
                            SettingRow(
                                icon: "square.and.arrow.up",
                                iconColor: DesignTokens.Colors.iconGreen,
                                title: "settings.share.title".localized,
                                subtitle: "settings.share.subtitle".localized,
                                showChevron: false
                            ) {
                                viewModel.shareApp()
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.xxl)
                    .cardStyle(
                        cornerRadius: DesignTokens.CornerRadius.xlarge,
                        fillColor: DesignTokens.Colors.cardBackground,
                        borderColor: DesignTokens.Colors.iconGreen.opacity(0.3),
                        shadowColor: Color.black.opacity(0.2),
                        shadowRadius: 8,
                        shadowYOffset: 4
                    )
                    
                    // MARK: - About Section
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("settings.about".localized)
                            .font(DesignTokens.Typography.h2)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            // App Version
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(DesignTokens.Colors.iconBlue)
                                    .frame(width: DesignTokens.Sizes.iconLarge)
                                
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                    Text("settings.version.title".localized)
                                        .font(DesignTokens.Typography.bodyRegular)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                        .font(DesignTokens.Typography.label)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            
                            Divider()
                                .background(DesignTokens.Colors.borderSubtle)
                            
                            // Privacy Policy
                            SettingRow(
                                icon: "hand.raised",
                                iconColor: DesignTokens.Colors.iconRed,
                                title: "settings.privacy.title".localized,
                                subtitle: nil,
                                showChevron: false
                            ) {
                                viewModel.openPrivacyPolicy()
                            }
                            
                            Divider()
                                .background(DesignTokens.Colors.borderSubtle)
                            
                            // Terms of Service
                            SettingRow(
                                icon: "doc.text",
                                iconColor: DesignTokens.Colors.textSecondary,
                                title: "settings.terms.title".localized,
                                subtitle: nil,
                                showChevron: false
                            ) {
                                viewModel.openTermsOfService()
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.xxl)
                    .cardStyle(
                        cornerRadius: DesignTokens.CornerRadius.xlarge,
                        fillColor: DesignTokens.Colors.cardBackground,
                        borderColor: DesignTokens.Colors.iconPurple.opacity(0.3),
                        shadowColor: Color.black.opacity(0.2),
                        shadowRadius: 8,
                        shadowYOffset: 4
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
        .id(viewModel.refreshTrigger)
        .navigationTitle("settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("settings.done".localized) {
                    dismiss()
                }
                .font(DesignTokens.Typography.secondarySemibold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            }
        }
        .toolbarBackground(DesignTokens.Colors.background1, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $viewModel.showingLanguagePicker) {
            NavigationStack {
                LanguagePickerView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NavigationStack {
                NotificationSettingsView()
                    .environment(\.notificationManager, notificationManager)
            }
        }
        .sheet(isPresented: $viewModel.showingPrivacyPolicy) {
            NavigationStack {
                PrivacyPolicyView()
            }
        }
        .sheet(isPresented: $viewModel.showingTermsOfService) {
            NavigationStack {
                TermsOfServiceView()
            }
        }
    }
    
    struct SettingRow: View {
        let icon: String
        let iconColor: Color
        let title: String
        let subtitle: String?
        let showChevron: Bool
        let action: () -> Void
        
        var body: some View {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: DesignTokens.Sizes.iconLarge)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(title)
                        .font(DesignTokens.Typography.bodyRegular)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(DesignTokens.Typography.label)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: DesignTokens.Sizes.iconSmall))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.xs)
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
        }
    }
    
    struct LanguagePickerView: View {
        @Bindable var viewModel: SettingsViewModel
        @Environment(\.dismiss) private var dismiss
        
        init(viewModel: SettingsViewModel) {
            _viewModel = Bindable(viewModel)
        }
        
        var body: some View {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.background1,
                        DesignTokens.Colors.background2
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            HStack {
                                Text(language.displayName)
                                    .font(DesignTokens.Typography.bodyRegular)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Spacer()
                                
                                if viewModel.settings.language == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignTokens.Colors.iconBlue)
                                }
                            }
                            .padding(DesignTokens.Spacing.lg)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.updateLanguage(language)
                                dismiss()
                            }
                            
                            if language != AppLanguage.allCases.last {
                                Divider()
                                    .background(DesignTokens.Colors.borderSubtle)
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.xxl)
                    .cardStyle(
                        cornerRadius: DesignTokens.CornerRadius.xlarge,
                        fillColor: DesignTokens.Colors.cardBackground,
                        borderColor: DesignTokens.Colors.iconOrange.opacity(0.3),
                        shadowColor: Color.black.opacity(0.2),
                        shadowRadius: 8,
                        shadowYOffset: 4
                    )
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    .padding(.top, DesignTokens.Spacing.lg)
                }
            }
            .navigationTitle("settings.language.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("settings.done".localized) {
                        dismiss()
                    }
                    .font(DesignTokens.Typography.secondarySemibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                }
            }
            .toolbarBackground(DesignTokens.Colors.background1, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct SettingsViewWithDependencies: View {
    @Environment(\.localizationProvider) private var localizationProvider
    @Environment(\.achievementManager) private var achievementManager
    let settingsManager: SettingsManager
    
    var body: some View {
        SettingsView(
            viewModel: SettingsViewModel(
                settingsManager: settingsManager,
                localizationProvider: localizationProvider,
                achievementManager: achievementManager
            )
        )
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(settingsManager: SettingsManager()))
}
