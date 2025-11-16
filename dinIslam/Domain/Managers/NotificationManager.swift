//
//  NotificationManager.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import UserNotifications
import OSLog
import SwiftUI
import Combine

class NotificationManager: ObservableObject {
    @Published var isNotificationEnabled = false
    @Published var reminderTime = Date()
    @Published var hasPermission = false
    
    private let center = UNUserNotificationCenter.current()
    private let localizationProvider: LocalizationProviding
    
    init(localizationProvider: LocalizationProviding? = nil) {
        self.localizationProvider = localizationProvider ?? LocalizationManager()
        checkNotificationPermission()
        loadSettings()
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.hasPermission = granted
                if granted {
                    self.isNotificationEnabled = true
                    // Schedule notifications if enabled
                    if self.isNotificationEnabled {
                        self.scheduleDailyReminder()
                    }
                }
            }
            return granted
        } catch {
            AppLogger.error("Error requesting notification permission", error: error, category: AppLogger.ui)
            return false
        }
    }
    
    private func checkNotificationPermission() {
        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleDailyReminder() {
        guard hasPermission && isNotificationEnabled else { return }
        
        // Remove existing daily reminder notifications only
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = localizationProvider.localizedString(for: "notification.title")
        content.body = localizationProvider.localizedString(for: "notification.body")
        content.sound = .default
        content.badge = 1
        
        // Create date components for the reminder time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                AppLogger.error("Error scheduling notification", error: error, category: AppLogger.ui)
            } else {
                AppLogger.ui.info("Daily reminder scheduled successfully")
            }
        }
    }
    
    func cancelDailyReminder() {
        // Remove only daily reminder notifications, not achievement notifications
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder", "streak_reminder"])
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        isNotificationEnabled = UserDefaults.standard.bool(forKey: "notification_enabled")
        
        if let savedTime = UserDefaults.standard.object(forKey: "reminder_time") as? Date {
            reminderTime = savedTime
        } else {
            // Default to 8:00 PM
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = 20
            components.minute = 0
            reminderTime = calendar.date(from: components) ?? Date()
        }
        
        // Schedule notifications if enabled and permission is granted
        // Check permission asynchronously and schedule if needed
        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.hasPermission = settings.authorizationStatus == .authorized
                if self.hasPermission && self.isNotificationEnabled {
                    self.scheduleDailyReminder()
                }
            }
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(isNotificationEnabled, forKey: "notification_enabled")
        UserDefaults.standard.set(reminderTime, forKey: "reminder_time")
        
        if isNotificationEnabled {
            scheduleDailyReminder()
        } else {
            cancelDailyReminder()
        }
    }
    
    func updateReminderTime(_ newTime: Date) {
        reminderTime = newTime
        saveSettings()
    }
    
    func toggleNotifications(_ enabled: Bool) {
        isNotificationEnabled = enabled
        saveSettings()
    }
    
    // MARK: - Achievement Notifications
    
    func scheduleAchievementNotification(for achievement: Achievement) {
        guard hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = localizationProvider.localizedString(for: "achievement.notification.title")
        content.body = "\(localizationProvider.localizedString(for: "achievement.notification.body")) \(achievement.title)"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                AppLogger.error("Error scheduling achievement notification", error: error, category: AppLogger.ui)
            }
        }
    }
    
    // MARK: - Streak Reminders
    
    func scheduleStreakReminder() {
        guard hasPermission && isNotificationEnabled else { return }
        
        // Schedule a reminder for the next day if user hasn't studied today
        let content = UNMutableNotificationContent()
        content.title = localizationProvider.localizedString(for: "streak.notification.title")
        content.body = localizationProvider.localizedString(for: "streak.notification.body")
        content.sound = .default
        content.badge = 1
        
        // Schedule for tomorrow at the same time
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: tomorrow)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                AppLogger.error("Error scheduling streak reminder", error: error, category: AppLogger.ui)
            }
        }
    }
}
