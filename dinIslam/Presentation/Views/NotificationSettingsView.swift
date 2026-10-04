//
//  NotificationSettingsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.notificationManager) private var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingPermissionAlert = false
    @State private var isNotificationEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxxl) {
                    // Permission Section
                    if !notificationManager.hasPermission {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "bell.badge")
                                    .foregroundStyle(DesignTokens.Colors.iconBlue)
                                    .font(.system(size: DesignTokens.Sizes.iconLarge))
                                    .frame(width: DesignTokens.Sizes.iconLarge)
                                
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                    Text("notification.permission.title".localized)
                                        .font(DesignTokens.Typography.bodyRegular)
                                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                                    
                                    // После отказа системный запрос не появится — объясняем, где включить
                                    Text((notificationManager.isPermissionDenied ?
                                          "notification.permission.denied.message" :
                                          "notification.permission.message").localized)
                                        .font(DesignTokens.Typography.label)
                                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            
                            Button(action: {
                                if notificationManager.isPermissionDenied {
                                    openNotificationSettings()
                                    return
                                }
                                Task {
                                    let granted = await notificationManager.requestNotificationPermission()
                                    if !granted {
                                        showingPermissionAlert = true
                                    }
                                }
                            }) {
                                Text((notificationManager.isPermissionDenied ?
                                      "notification.permission.openSettings" :
                                      "notification.permission.request").localized)
                                    .font(DesignTokens.Typography.secondarySemibold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                DesignTokens.Colors.iconBlue.opacity(0.8),
                                                DesignTokens.Colors.iconBlueLight.opacity(0.8)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(GlowBorder())
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                            }
                        }
                        .padding(DesignTokens.Spacing.xxl)
                        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
                    }
                    
                    // Settings Section
                    if notificationManager.hasPermission {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                            Text("notification.settings.title".localized)
                                .font(DesignTokens.Typography.h2)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                            
                            VStack(spacing: DesignTokens.Spacing.sm) {
                                // Enable/Disable Notifications
                                Toggle(isOn: $isNotificationEnabled) {
                                    HStack(spacing: DesignTokens.Spacing.md) {
                                        Image(systemName: "bell")
                                            .foregroundStyle(DesignTokens.Colors.iconPurple)
                                            .font(.system(size: DesignTokens.Sizes.iconMedium))
                                            .frame(width: DesignTokens.Sizes.iconLarge)
                                            .accessibilityHidden(true)
                                        
                                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                            Text("notification.settings.enabled".localized)
                                                .font(DesignTokens.Typography.bodyRegular)
                                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                                            
                                            // Состояние и так озвучивает переключатель
                                            Text(isNotificationEnabled ?
                                                 "settings.on".localized :
                                                 "settings.off".localized)
                                                .font(DesignTokens.Typography.label)
                                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                                                .accessibilityHidden(true)
                                        }
                                    }
                                }
                                .tint(DesignTokens.Colors.iconPurple)
                                .onChange(of: isNotificationEnabled) { _, newValue in
                                    notificationManager.toggleNotifications(newValue)
                                }
                                .padding(.vertical, DesignTokens.Spacing.xs)
                                
                                // Reminder Time
                                if isNotificationEnabled {
                                    Divider()
                                        .overlay(Color.white.opacity(0.1))
                                    
                                    HStack(spacing: DesignTokens.Spacing.md) {
                                        Image(systemName: "clock")
                                            .foregroundStyle(DesignTokens.Colors.iconBlue)
                                            .font(.system(size: DesignTokens.Sizes.iconMedium))
                                            .frame(width: DesignTokens.Sizes.iconLarge)
                                        
                                        // Время показывает сам DatePicker, второй раз подписью не дублируем
                                        Text("notification.settings.time".localized)
                                            .font(DesignTokens.Typography.bodyRegular)
                                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                                            .accessibilityHidden(true)
                                        
                                        Spacer()
                                        
                                        DatePicker("notification.settings.time".localized, selection: $reminderTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                            .tint(DesignTokens.Colors.iconBlue)
                                            .onChange(of: reminderTime) { _, newValue in
                                                notificationManager.updateReminderTime(newValue)
                                            }
                                    }
                                    .padding(.vertical, DesignTokens.Spacing.xs)
                                    
                                    if isNotificationEnabled {
                                        Text("notification.settings.footer".localized)
                                            .font(DesignTokens.Typography.label)
                                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                                            .padding(.top, DesignTokens.Spacing.sm)
                                    }
                                }
                            }
                        }
                        .padding(DesignTokens.Spacing.xxl)
                        .glowBorder(cornerRadius: DesignTokens.CornerRadius.xlarge)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xxxl)
            }
        }
        .onAppear {
            isNotificationEnabled = notificationManager.isNotificationEnabled
            reminderTime = notificationManager.reminderTime
        }
        .onChange(of: notificationManager.isNotificationEnabled) { _, newValue in
            isNotificationEnabled = newValue
        }
        .onChange(of: notificationManager.reminderTime) { _, newValue in
            reminderTime = newValue
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Разрешение могли включить в Настройках, пока приложение было в фоне
            if newPhase == .active {
                notificationManager.checkNotificationPermission()
            }
        }
        .navigationTitle("notification.settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("settings.done".localized) {
                    dismiss()
                }
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
        }
        .alert("notification.permission.title".localized,
               isPresented: $showingPermissionAlert) {
            Button("notification.permission.openSettings".localized) {
                openNotificationSettings()
            }
            Button("error.ok".localized, role: .cancel) { }
        } message: {
            Text("notification.permission.denied.message".localized)
        }
    }
    
    private func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        }
    }
}

#Preview {
    NotificationSettingsView()
        .environment(\.notificationManager, NotificationManager())
}
