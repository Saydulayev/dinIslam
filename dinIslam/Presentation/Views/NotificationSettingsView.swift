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
    @State private var showingPermissionAlert = false
    @State private var isNotificationEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    
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
                    // Permission Section
                    if !notificationManager.hasPermission {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                            HStack(spacing: DesignTokens.Spacing.md) {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(DesignTokens.Colors.iconBlue)
                                    .font(.system(size: DesignTokens.Sizes.iconLarge))
                                    .frame(width: DesignTokens.Sizes.iconLarge)
                                
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                    Text("notification.permission.title".localized)
                                        .font(DesignTokens.Typography.bodyRegular)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    
                                    Text("notification.permission.message".localized)
                                        .font(DesignTokens.Typography.label)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            
                            Button(action: {
                                Task {
                                    let granted = await notificationManager.requestNotificationPermission()
                                    if !granted {
                                        showingPermissionAlert = true
                                    }
                                }
                            }) {
                                Text("notification.permission.request".localized)
                                    .font(DesignTokens.Typography.secondarySemibold)
                                    .foregroundColor(.white)
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
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
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
                                    .cornerRadius(DesignTokens.CornerRadius.medium)
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
                    
                    // Settings Section
                    if notificationManager.hasPermission {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                            Text("notification.settings.title".localized)
                                .font(DesignTokens.Typography.h2)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                            
                            VStack(spacing: DesignTokens.Spacing.sm) {
                                // Enable/Disable Notifications
                                HStack(spacing: DesignTokens.Spacing.md) {
                                    Image(systemName: "bell")
                                        .foregroundColor(DesignTokens.Colors.iconPurple)
                                        .font(.system(size: DesignTokens.Sizes.iconMedium))
                                        .frame(width: DesignTokens.Sizes.iconLarge)
                                    
                                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                        Text("notification.settings.enabled".localized)
                                            .font(DesignTokens.Typography.bodyRegular)
                                            .foregroundColor(DesignTokens.Colors.textPrimary)
                                        
                                        Text(isNotificationEnabled ?
                                             "settings.on".localized :
                                             "settings.off".localized)
                                            .font(DesignTokens.Typography.label)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $isNotificationEnabled)
                                        .tint(DesignTokens.Colors.iconPurple)
                                        .onChange(of: isNotificationEnabled) { _, newValue in
                                            notificationManager.toggleNotifications(newValue)
                                        }
                                }
                                .padding(.vertical, DesignTokens.Spacing.xs)
                                
                                // Reminder Time
                                if isNotificationEnabled {
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                    
                                    HStack(spacing: DesignTokens.Spacing.md) {
                                        Image(systemName: "clock")
                                            .foregroundColor(DesignTokens.Colors.iconBlue)
                                            .font(.system(size: DesignTokens.Sizes.iconMedium))
                                            .frame(width: DesignTokens.Sizes.iconLarge)
                                        
                                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                            Text("notification.settings.time".localized)
                                                .font(DesignTokens.Typography.bodyRegular)
                                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                            
                                            Text(reminderTime.formatted(date: .omitted, time: .shortened))
                                                .font(DesignTokens.Typography.label)
                                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
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
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                            .padding(.top, DesignTokens.Spacing.sm)
                                    }
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
        .navigationTitle("notification.settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar) // прозрачный toolbar для градиента
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("settings.done".localized) {
                    dismiss()
                }
                .foregroundColor(DesignTokens.Colors.textPrimary)
            }
        }
        .alert("notification.permission.title".localized,
               isPresented: $showingPermissionAlert) {
            Button("error.ok".localized) {
                showingPermissionAlert = false
            }
        } message: {
            Text("notification.permission.denied.message".localized)
        }
    }
}

#Preview {
    NotificationSettingsView()
        .environment(\.notificationManager, NotificationManager())
}
