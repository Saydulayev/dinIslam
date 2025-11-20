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
                                Text("notification.permission.title".localized)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("notification.permission.message".localized)
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
                            Text("notification.permission.request".localized)
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
                            Text("notification.settings.enabled".localized)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text(isNotificationEnabled ?
                                 "settings.on".localized :
                                 "settings.off".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isNotificationEnabled)
                            .onChange(of: isNotificationEnabled) { _, newValue in
                                notificationManager.toggleNotifications(newValue)
                            }
                    }
                    .padding(.vertical, 4)
                    
                    // Reminder Time
                    if isNotificationEnabled {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("notification.settings.time".localized)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text(reminderTime.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .onChange(of: reminderTime) { _, newValue in
                                    notificationManager.updateReminderTime(newValue)
                                }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("notification.settings.title".localized)
                } footer: {
                    if isNotificationEnabled {
                        Text("notification.settings.footer".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
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
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("settings.done".localized) {
                    dismiss()
                }
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
