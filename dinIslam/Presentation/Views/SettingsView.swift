//
//  SettingsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.notificationManager) private var notificationManager: NotificationManager
    @State private var showingNotificationSettings = false
    
    init(viewModel: SettingsViewModel) {
        _viewModel = Bindable(viewModel)
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
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
                                showChevron: true
                            ) {
                                viewModel.showingLanguagePicker = true
                            }
                            
                            Divider()
                                .overlay(Color.white.opacity(0.1))
                            
                            // Sound Setting
                            Toggle(isOn: Binding(
                                get: { viewModel.settings.soundEnabled },
                                set: { viewModel.updateSoundEnabled($0) }
                            )) {
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    Image(systemName: "speaker.wave.2")
                                        .foregroundStyle(DesignTokens.Colors.iconGreen)
                                        .frame(width: DesignTokens.Sizes.iconLarge)
                                        .accessibilityHidden(true)
                                    
                                    Text("settings.sound.title".localized)
                                        .font(DesignTokens.Typography.bodyRegular)
                                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                                }
                            }
                            .tint(DesignTokens.Colors.iconGreen)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            
                            Divider()
                                .overlay(Color.white.opacity(0.1))
                            
                            // Haptic Feedback Setting
                            Toggle(isOn: Binding(
                                get: { viewModel.settings.hapticEnabled },
                                set: { viewModel.updateHapticEnabled($0) }
                            )) {
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .foregroundStyle(DesignTokens.Colors.iconOrange)
                                        .frame(width: DesignTokens.Sizes.iconLarge)
                                        .accessibilityHidden(true)
                                    
                                    Text("settings.haptic.title".localized)
                                        .font(DesignTokens.Typography.bodyRegular)
                                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                                }
                            }
                            .tint(DesignTokens.Colors.iconOrange)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            
                            Divider()
                                .overlay(Color.white.opacity(0.1))
                            
                            // Notifications Setting
                            SettingRow(
                                icon: "bell",
                                iconColor: DesignTokens.Colors.iconPurple,
                                title: "settings.notifications.title".localized,
                                subtitle: nil,
                                showChevron: true
                            ) {
                                showingNotificationSettings = true
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.xxl)
                    .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
                    
                    // MARK: - Support Section
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("settings.support".localized)
                            .font(DesignTokens.Typography.h2)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            // Technical feedback
                            SettingRow(
                                icon: "gearshape",
                                iconColor: DesignTokens.Colors.iconBlue,
                                title: "settings.feedback.technical.title".localized,
                                subtitle: "settings.feedback.technical.subtitle".localized,
                                showChevron: false
                            ) {
                                sendFeedback(to: .technical)
                            }
                            
                            Divider()
                                .overlay(Color.white.opacity(0.1))
                            
                            // Religious questions
                            SettingRow(
                                icon: "book.closed",
                                iconColor: DesignTokens.Colors.iconPurpleLight,
                                title: "settings.feedback.religious.title".localized,
                                subtitle: "settings.feedback.religious.subtitle".localized,
                                showChevron: false
                            ) {
                                sendFeedback(to: .religious)
                            }
                            
                            Divider()
                                .overlay(Color.white.opacity(0.1))
                            
                            // Rate App
                            SettingRow(
                                icon: "star",
                                iconColor: .yellow,
                                title: "settings.rate.title".localized,
                                subtitle: "settings.rate.subtitle".localized,
                                showChevron: false
                            ) {
                                if let url = viewModel.writeReviewURL {
                                    openURL(url)
                                }
                            }
                            
                            Divider()
                                .overlay(Color.white.opacity(0.1))
                            
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
                    .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
                    
                    // MARK: - About Section
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("settings.about".localized)
                            .font(DesignTokens.Typography.h2)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            // App Version
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(DesignTokens.Colors.iconBlue)
                                    .frame(width: DesignTokens.Sizes.iconLarge)
                                
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                    Text("settings.version.title".localized)
                                        .font(DesignTokens.Typography.bodyRegular)
                                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                                    Text(appVersion)
                                        .font(DesignTokens.Typography.label)
                                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            
                            Divider()
                                .overlay(Color.white.opacity(0.1))
                            
                            // Privacy Policy
                            SettingRow(
                                icon: "hand.raised",
                                iconColor: DesignTokens.Colors.iconRed,
                                title: "settings.privacy.title".localized,
                                subtitle: nil,
                                showChevron: true
                            ) {
                                viewModel.openPrivacyPolicy()
                            }
                            
                            Divider()
                                .overlay(Color.white.opacity(0.1))
                            
                            // Terms of Service
                            SettingRow(
                                icon: "doc.text",
                                iconColor: DesignTokens.Colors.textSecondary,
                                title: "settings.terms.title".localized,
                                subtitle: nil,
                                showChevron: true
                            ) {
                                viewModel.openTermsOfService()
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.xxl)
                    .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
        .id(viewModel.refreshTrigger)
        .navigationTitle("settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
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
        .alert(
            "settings.feedback.mailUnavailable.title".localized,
            isPresented: Binding(
                get: { viewModel.unavailableMailRecipient != nil },
                set: { if !$0 { viewModel.unavailableMailRecipient = nil } }
            ),
            presenting: viewModel.unavailableMailRecipient
        ) { recipient in
            Button("settings.feedback.mailUnavailable.copy".localized) {
                UIPasteboard.general.string = recipient.address
            }
            Button("error.ok".localized, role: .cancel) { }
        } message: { recipient in
            Text(String(format: "settings.feedback.mailUnavailable.message".localized, recipient.address))
        }
    }
    
    /// Версия с номером сборки — например «1.2 (34)», чтобы в обращениях было видно точную сборку
    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        guard let build = info?["CFBundleVersion"] as? String else { return version }
        return "\(version) (\(build))"
    }
    
    /// Без настроенной почты mailto: не открывается — тогда показываем адрес,
    /// чтобы его можно было скопировать
    private func sendFeedback(to recipient: SettingsViewModel.FeedbackRecipient) {
        guard let url = recipient.mailURL else { return }
        openURL(url) { accepted in
            if !accepted {
                viewModel.unavailableMailRecipient = recipient
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
            Button(action: action) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .frame(width: DesignTokens.Sizes.iconLarge)
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(title)
                            .font(DesignTokens.Typography.bodyRegular)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(DesignTokens.Typography.label)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    if showChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: DesignTokens.Sizes.iconSmall))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.xs)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
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
                AppBackground()
                
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Button {
                                viewModel.updateLanguage(language)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(language.displayName)
                                        .font(DesignTokens.Typography.bodyRegular)
                                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    if viewModel.settings.language == language {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(DesignTokens.Colors.iconBlue)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .padding(DesignTokens.Spacing.lg)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.pressable)
                            .accessibilityAddTraits(viewModel.settings.language == language ? .isSelected : [])
                            
                            if language != AppLanguage.allCases.last {
                                Divider()
                                    .overlay(Color.white.opacity(0.1))
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.xxl)
                    .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    .padding(.top, DesignTokens.Spacing.lg)
                    
                    // Системные элементы берут язык при запуске приложения (см. SettingsManager)
                    Text("settings.language.restartHint".localized)
                        .font(DesignTokens.Typography.label)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DesignTokens.Spacing.xxl + DesignTokens.Spacing.lg)
                        .padding(.top, DesignTokens.Spacing.sm)
                }
            }
            .navigationTitle("settings.language.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("settings.done".localized) {
                        dismiss()
                    }
                    .font(DesignTokens.Typography.secondarySemibold)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct SettingsViewWithDependencies: View {
    @Environment(\.localizationProvider) private var localizationProvider
    @Environment(\.achievementManager) private var achievementManager
    let settingsManager: SettingsManager
    /// ViewModel создаётся один раз: иначе каждая перерисовка сбрасывала бы её состояние (открытые листы)
    @State private var viewModel: SettingsViewModel?
    
    var body: some View {
        if let viewModel {
            SettingsView(viewModel: viewModel)
        } else {
            Color.clear
                .onAppear {
                    viewModel = SettingsViewModel(
                        settingsManager: settingsManager,
                        localizationProvider: localizationProvider,
                        achievementManager: achievementManager
                    )
                }
        }
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(settingsManager: SettingsManager()))
}
