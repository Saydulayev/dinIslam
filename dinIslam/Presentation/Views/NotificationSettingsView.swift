//
//  NotificationSettingsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager()
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingPermissionAlert = false
    @State private var showingTestNotification = false
    
    var body: some View {
        NavigationStack {
            List {
                // Permission Section
                if !notificationManager.hasPermission {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizationManager.shared.localizedString(for: "notification.permission.title"))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(LocalizationManager.shared.localizedString(for: "notification.permission.message"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
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
                                Text(LocalizationManager.shared.localizedString(for: "notification.permission.title"))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Settings Section
                if notificationManager.hasPermission {
                    Section {
                        // Enable/Disable Notifications
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizationManager.shared.localizedString(for: "notification.settings.enabled"))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text(notificationManager.isNotificationEnabled ? 
                                     LocalizationManager.shared.localizedString(for: "settings.on") : 
                                     LocalizationManager.shared.localizedString(for: "settings.off"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $notificationManager.isNotificationEnabled)
                                .onChange(of: notificationManager.isNotificationEnabled) { _, newValue in
                                    notificationManager.toggleNotifications(newValue)
                                }
                        }
                        .padding(.vertical, 4)
                        
                        // Reminder Time
                        if notificationManager.isNotificationEnabled {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LocalizationManager.shared.localizedString(for: "notification.settings.time"))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text(notificationManager.reminderTime.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                DatePicker("", selection: $notificationManager.reminderTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .onChange(of: notificationManager.reminderTime) { _, newValue in
                                        notificationManager.updateReminderTime(newValue)
                                    }
                            }
                            .padding(.vertical, 4)
                            
                            // Test Notification Button
                            Button(action: {
                                sendTestNotification()
                            }) {
                                HStack {
                                    Image(systemName: "paperplane")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    Text(LocalizationManager.shared.localizedString(for: "notification.settings.test"))
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } header: {
                        Text(LocalizationManager.shared.localizedString(for: "notification.settings.title"))
                    } footer: {
                        if notificationManager.isNotificationEnabled {
                            Text(LocalizationManager.shared.localizedString(for: "notification.settings.footer"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString(for: "notification.settings.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString(for: "settings.done")) {
                        dismiss()
                    }
                }
            }
            .alert(LocalizationManager.shared.localizedString(for: "notification.permission.title"),
                   isPresented: $showingPermissionAlert) {
                Button(LocalizationManager.shared.localizedString(for: "error.ok")) {
                    showingPermissionAlert = false
                }
            } message: {
                Text(LocalizationManager.shared.localizedString(for: "notification.permission.denied.message"))
            }
            .alert(LocalizationManager.shared.localizedString(for: "notification.test.sent.title"),
                   isPresented: $showingTestNotification) {
                Button(LocalizationManager.shared.localizedString(for: "error.ok")) {
                    showingTestNotification = false
                }
            } message: {
                Text(LocalizationManager.shared.localizedString(for: "notification.test.sent.message"))
            }
        }
    }
    
    private func sendTestNotification() {
        guard notificationManager.hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = LocalizationManager.shared.localizedString(for: "notification.title")
        content.body = LocalizationManager.shared.localizedString(for: "notification.body")
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if error == nil {
                    showingTestNotification = true
                }
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
