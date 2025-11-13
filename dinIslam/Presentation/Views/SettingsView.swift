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
    @EnvironmentObject private var notificationManager: NotificationManager
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
            
            List {
                // MARK: - App Settings Section
                Section {
                    // Language Setting
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "globe")
                            .foregroundColor(DesignTokens.Colors.iconBlue)
                            .frame(width: DesignTokens.Sizes.iconLarge)
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            LocalizedText("settings.language.title")
                                .font(DesignTokens.Typography.bodyRegular)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            Text(viewModel.settings.language.displayName)
                                .font(DesignTokens.Typography.label)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: DesignTokens.Sizes.iconSmall))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.showingLanguagePicker = true
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                    
                    // Theme Setting
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "paintbrush")
                            .foregroundColor(DesignTokens.Colors.iconPurple)
                            .frame(width: DesignTokens.Sizes.iconLarge)
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            LocalizedText("settings.theme.title")
                                .font(DesignTokens.Typography.bodyRegular)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            Text(viewModel.settings.theme.displayName)
                                .font(DesignTokens.Typography.label)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: DesignTokens.Sizes.iconSmall))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.showingThemePicker = true
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                    
                    // Sound Setting
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(DesignTokens.Colors.iconGreen)
                            .frame(width: DesignTokens.Sizes.iconLarge)
                        
                        LocalizedText("settings.sound.title")
                            .font(DesignTokens.Typography.bodyRegular)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { viewModel.settings.soundEnabled },
                            set: { viewModel.updateSoundEnabled($0) }
                        ))
                        .tint(DesignTokens.Colors.iconGreen)
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                    
                    // Haptic Feedback Setting
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundColor(DesignTokens.Colors.iconOrange)
                            .frame(width: DesignTokens.Sizes.iconLarge)
                        
                        LocalizedText("settings.haptic.title")
                            .font(DesignTokens.Typography.bodyRegular)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { viewModel.settings.hapticEnabled },
                            set: { viewModel.updateHapticEnabled($0) }
                        ))
                        .tint(DesignTokens.Colors.iconOrange)
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                    
                    // Notifications Setting
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "bell")
                            .foregroundColor(DesignTokens.Colors.iconPurple)
                            .frame(width: DesignTokens.Sizes.iconLarge)
                        
                        LocalizedText("settings.notifications.title")
                            .font(DesignTokens.Typography.bodyRegular)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: DesignTokens.Sizes.iconSmall))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingNotificationSettings = true
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                } header: {
                    LocalizedText("settings.appSettings")
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .listSectionSpacing(DesignTokens.Spacing.lg)
                
                // MARK: - Support Section
                Section {
                    // Send Feedback
                    SettingsRow(
                        icon: "envelope",
                        iconColor: DesignTokens.Colors.iconBlue,
                        title: "settings.feedback.title",
                        subtitle: "settings.feedback.subtitle"
                    ) {
                        if let url = URL(string: "mailto:saydulayev.wien@gmail.com?subject=Feedback&body=") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                    
                    // Rate App
                    SettingsRow(
                        icon: "star",
                        iconColor: .yellow,
                        title: "settings.rate.title",
                        subtitle: "settings.rate.subtitle"
                    ) {
                        viewModel.requestAppReview()
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                    
                    // Share App
                    SettingsRow(
                        icon: "square.and.arrow.up",
                        iconColor: DesignTokens.Colors.iconGreen,
                        title: "settings.share.title",
                        subtitle: "settings.share.subtitle"
                    ) {
                        viewModel.shareApp()
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                } header: {
                    LocalizedText("settings.support")
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .listSectionSpacing(DesignTokens.Spacing.lg)
                
                // MARK: - About Section
                Section {
                    // App Version
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "info.circle")
                            .foregroundColor(DesignTokens.Colors.iconBlue)
                            .frame(width: DesignTokens.Sizes.iconLarge)
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            LocalizedText("settings.version.title")
                                .font(DesignTokens.Typography.bodyRegular)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .font(DesignTokens.Typography.label)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                    
                    // Privacy Policy
                    SettingsRow(
                        icon: "hand.raised",
                        iconColor: DesignTokens.Colors.iconRed,
                        title: "settings.privacy.title",
                        subtitle: nil
                    ) {
                        viewModel.openPrivacyPolicy()
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                    
                    // Terms of Service
                    SettingsRow(
                        icon: "doc.text",
                        iconColor: DesignTokens.Colors.textSecondary,
                        title: "settings.terms.title",
                        subtitle: nil
                    ) {
                        viewModel.openTermsOfService()
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                } header: {
                    LocalizedText("settings.about")
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .listSectionSpacing(DesignTokens.Spacing.lg)
                
                // MARK: - Reset Section
                Section {
                    Button(action: {
                        viewModel.resetSettings()
                    }) {
                        HStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(DesignTokens.Colors.iconRed)
                                .frame(width: DesignTokens.Sizes.iconLarge)
                            
                            LocalizedText("settings.reset.title")
                                .font(DesignTokens.Typography.bodyRegular)
                                .foregroundColor(DesignTokens.Colors.iconRed)
                            
                            Spacer()
                        }
                    }
                    .listRowBackground(DesignTokens.Colors.cardBackground)
                } header: {
                    LocalizedText("settings.dangerZone")
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                } footer: {
                    LocalizedText("settings.reset.footer")
                        .font(DesignTokens.Typography.label)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
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
        .sheet(isPresented: $viewModel.showingThemePicker) {
            NavigationStack {
                ThemePickerView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NavigationStack {
                NotificationSettingsView()
                    .environmentObject(notificationManager)
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
    
    struct SettingsRow: View {
        let icon: String
        let iconColor: Color
        let title: String
        let subtitle: String?
        let action: () -> Void
        
        var body: some View {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: DesignTokens.Sizes.iconLarge)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    LocalizedText(title)
                        .font(DesignTokens.Typography.bodyRegular)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    if let subtitle = subtitle {
                        LocalizedText(subtitle)
                            .font(DesignTokens.Typography.label)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: DesignTokens.Sizes.iconSmall))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
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
                
                List {
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
                        .listRowBackground(DesignTokens.Colors.cardBackground)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.updateLanguage(language)
                            dismiss()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
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
    
    struct ThemePickerView: View {
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
                
                List {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        HStack {
                            Text(theme.displayName)
                                .font(DesignTokens.Typography.bodyRegular)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Spacer()
                            
                            if viewModel.settings.theme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(DesignTokens.Colors.iconBlue)
                            }
                        }
                        .listRowBackground(DesignTokens.Colors.cardBackground)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.updateTheme(theme)
                            dismiss()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("settings.theme.title".localized)
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

#Preview {
    SettingsView(viewModel: SettingsViewModel(settingsManager: SettingsManager()))
}
