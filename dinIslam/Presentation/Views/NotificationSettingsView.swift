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
                            Text("Вы будете получать напоминания каждый день в выбранное время.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Information Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("О напоминаниях")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Получайте ежедневные напоминания о изучении ислама для поддержания постоянства в знаниях.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text("Ежедневные напоминания о изучении")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text("Уведомления о новых достижениях")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text("Напоминания о поддержании серии")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
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
                Text("Для получения напоминаний необходимо разрешить уведомления в настройках приложения.")
            }
            .alert("Тестовое уведомление",
                   isPresented: $showingTestNotification) {
                Button("OK") {
                    showingTestNotification = false
                }
            } message: {
                Text("Тестовое уведомление отправлено!")
            }
        }
    }
    
    private func sendTestNotification() {
        guard notificationManager.hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = LocalizationManager.shared.localizedString(for: "notification.title")
        content.body = LocalizationManager.shared.localizedString(for: "notification.body")
        content.sound = .default
        
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
