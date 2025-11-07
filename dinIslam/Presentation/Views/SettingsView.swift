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
    @State private var showingNotificationSettings = false
    
    init(viewModel: SettingsViewModel) {
        _viewModel = Bindable(viewModel)
    }
    
    var body: some View {
        List {
            // MARK: - App Settings Section
            Section {
                // Language Setting
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        LocalizedText("settings.language.title")
                            .font(.body)
                        Text(viewModel.settings.language.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.showingLanguagePicker = true
                }
                
                // Sound Setting
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    LocalizedText("settings.sound.title")
                        .font(.body)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { viewModel.settings.soundEnabled },
                        set: { viewModel.updateSoundEnabled($0) }
                    ))
                }
                
                // Haptic Feedback Setting
                HStack {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    
                    LocalizedText("settings.haptic.title")
                        .font(.body)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { viewModel.settings.hapticEnabled },
                        set: { viewModel.updateHapticEnabled($0) }
                    ))
                }
                
                // Notifications Setting
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    
                    LocalizedText("settings.notifications.title")
                        .font(.body)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showingNotificationSettings = true
                }
            } header: {
                LocalizedText("settings.appSettings")
            }
            
            // MARK: - Support Section
            Section {
                // Send Feedback
                SettingsRow(
                    icon: "envelope",
                    iconColor: .blue,
                    title: "settings.feedback.title",
                    subtitle: "settings.feedback.subtitle"
                ) {
                    // Open email client directly
                    if let url = URL(string: "mailto:saydulayev.wien@gmail.com?subject=Feedback&body=") {
                        UIApplication.shared.open(url)
                    }
                }
                
                // Rate App
                SettingsRow(
                    icon: "star",
                    iconColor: .yellow,
                    title: "settings.rate.title",
                    subtitle: "settings.rate.subtitle"
                ) {
                    viewModel.requestAppReview()
                }
                
                // Share App
                SettingsRow(
                    icon: "square.and.arrow.up",
                    iconColor: .green,
                    title: "settings.share.title",
                    subtitle: "settings.share.subtitle"
                ) {
                    viewModel.shareApp()
                }
            } header: {
                LocalizedText("settings.support")
            }
            
            // MARK: - About Section
            Section {
                // App Version
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        LocalizedText("settings.version.title")
                            .font(.body)
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Privacy Policy
                SettingsRow(
                    icon: "hand.raised",
                    iconColor: .red,
                    title: "settings.privacy.title",
                    subtitle: nil
                ) {
                    viewModel.openPrivacyPolicy()
                }
                
                // Terms of Service
                SettingsRow(
                    icon: "doc.text",
                    iconColor: .gray,
                    title: "settings.terms.title",
                    subtitle: nil
                ) {
                    viewModel.openTermsOfService()
                }
            } header: {
                LocalizedText("settings.about")
            }
            
            // MARK: - Reset Section
            Section {
                Button(action: {
                    viewModel.resetSettings()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        LocalizedText("settings.reset.title")
                            .font(.body)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                }
            } header: {
                LocalizedText("settings.dangerZone")
            } footer: {
                LocalizedText("settings.reset.footer")
            }
        }
        .id(viewModel.refreshTrigger)
        .navigationTitle("settings.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("settings.done".localized) {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $viewModel.showingLanguagePicker) {
            NavigationStack {
                LanguagePickerView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
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
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    LocalizedText(title)
                        .font(.body)
                    
                    if let subtitle = subtitle {
                        LocalizedText(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
            List {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    HStack {
                        Text(language.displayName)
                            .font(.body)
                        
                        Spacer()
                        
                        if viewModel.settings.language == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.updateLanguage(language)
                        dismiss()
                    }
                }
            }
            .navigationTitle("settings.language.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("settings.done".localized) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel(settingsManager: SettingsManager()))
}
