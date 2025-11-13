//
//  NotificationSettingsView.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false
    
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
                            
                            Text(notificationManager.isNotificationEnabled ?
                                 "settings.on".localized :
                                 "settings.off".localized)
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
                                Text("notification.settings.time".localized)
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
                    }
                } header: {
                    Text("notification.settings.title".localized)
                } footer: {
                    if notificationManager.isNotificationEnabled {
                        Text("notification.settings.footer".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
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
        .environmentObject(NotificationManager())
}
