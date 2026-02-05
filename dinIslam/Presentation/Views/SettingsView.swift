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
                                .background(Color.white.opacity(0.1))
                            
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
                                .background(Color.white.opacity(0.1))
                            
                            // Haptic Feedback Setting
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .foregroundColor(DesignTokens.Colors.iconOrange)
                                    .frame(width: DesignTokens.Sizes.iconLarge)
                                
                                Text("settings.haptic.title".localized)
                                    .font(DesignTokens.Typography.bodyRegular)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { viewModel.settings.hapticEnabled },
                                    set: { viewModel.updateHapticEnabled($0) }
                                ))
                                .tint(DesignTokens.Colors.iconOrange)
                            }
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
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
                    .background(
                        // Прозрачная рамка с фиолетовым свечением (как на главном экране)
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
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
                                let techSubject = "settings.feedback.technical.subject".localized.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Technical"
                                if let url = URL(string: "mailto:saydulayev.wien@gmail.com?subject=\(techSubject)&body=") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            // Religious questions
                            SettingRow(
                                icon: "book.closed",
                                iconColor: DesignTokens.Colors.iconPurpleLight,
                                title: "settings.feedback.religious.title".localized,
                                subtitle: "settings.feedback.religious.subtitle".localized,
                                showChevron: false
                            ) {
                                let relSubject = "settings.feedback.religious.subject".localized.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Religious"
                                if let url = URL(string: "mailto:amigomuslim65@gmail.com?subject=\(relSubject)&body=") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
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
                                .background(Color.white.opacity(0.1))
                            
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
                    .background(
                        // Прозрачная рамка с фиолетовым свечением (как на главном экране)
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
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
                                .background(Color.white.opacity(0.1))
                            
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
                                .background(Color.white.opacity(0.1))
                            
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
                    .background(
                        // Прозрачная рамка с фиолетовым свечением (как на главном экране)
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
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
        .toolbarBackground(.clear, for: .navigationBar) // прозрачный toolbar для градиента
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
                                    .background(Color.white.opacity(0.1))
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.xxl)
                    .background(
                        // Прозрачная рамка с фиолетовым свечением (как на главном экране)
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xlarge)
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
            .toolbarBackground(.clear, for: .navigationBar) // прозрачный toolbar для градиента
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
