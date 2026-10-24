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

/// Данные для ежедневного напоминания (StatsManager)
protocol DailyReminderContextProviding: AnyObject {
    /// Занятие сегодня уже было — сегодняшнее напоминание не нужно
    var isActiveToday: Bool { get }
    func dueReviewCount(at date: Date) -> Int
}

/// @Observable: экраны получают менеджер через кастомный @Environment-ключ,
/// и SwiftUI отслеживает чтение свойств только у @Observable-объектов
@Observable
class NotificationManager {
    var isNotificationEnabled = false
    var reminderTime = Date()
    var hasPermission = false
    /// Пользователь отказал: системный запрос больше не появится, включить можно только в Настройках
    var isPermissionDenied = false
    
    /// Откуда напоминание узнаёт о сегодняшних занятиях и ошибках к повторению
    @ObservationIgnored weak var reminderContext: DailyReminderContextProviding?
    
    @ObservationIgnored private let center = UNUserNotificationCenter.current()
    @ObservationIgnored private let localizationProvider: LocalizationProviding
    @ObservationIgnored private var dataChangeTask: Task<Void, Never>?
    
    /// На сколько дней вперёд планируются напоминания. Каждый день — отдельный запрос:
    /// так текст учитывает ошибки к повторению на этот день, а сегодняшнее можно пропустить
    static let reminderDays = 7
    private static let reminderIds = (0..<reminderDays).map { "daily_reminder_\($0)" }
    /// Повторяющееся напоминание и напоминание о серии из прежних версий
    private static let legacyReminderIds = ["daily_reminder", "streak_reminder"]
    
    init(localizationProvider: LocalizationProviding? = nil) {
        self.localizationProvider = localizationProvider ?? LocalizationManager()
        checkNotificationPermission()
        loadSettings()
        
        // После занятия (и любого другого изменения данных) сегодняшнее напоминание уже не нужно
        dataChangeTask = Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .syncedDataDidChange) {
                self?.scheduleDailyReminder()
            }
        }
    }
    
    deinit {
        dataChangeTask?.cancel()
    }
    
    // MARK: - Permission Management
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.hasPermission = granted
                self.isPermissionDenied = !granted
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
    
    /// Вызывается и при возврате в приложение: разрешение могли изменить в Настройках
    func checkNotificationPermission() {
        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.hasPermission = settings.authorizationStatus == .authorized
                self.isPermissionDenied = settings.authorizationStatus == .denied
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    /// Перепланирует напоминания на ближайшие дни: текст — на текущем языке,
    /// сегодня — только если занятий ещё не было. Вызывается при изменении данных,
    /// уходе приложения в фон и смене языка
    func scheduleDailyReminder() {
        // Без данных о занятиях (экземпляры для превью и запасные) не планируем:
        // иначе они перезаписали бы напоминания основного экземпляра
        guard hasPermission && isNotificationEnabled, let reminderContext else { return }
        
        cancelDailyReminder()
        
        let calendar = Calendar.current
        let dates = Self.reminderDates(
            now: Date(),
            reminderTime: reminderTime,
            isActiveToday: reminderContext.isActiveToday,
            calendar: calendar
        )
        
        for (identifier, date) in zip(Self.reminderIds, dates) {
            let content = UNMutableNotificationContent()
            content.title = localizationProvider.localizedString(for: "notification.title")
            content.body = reminderBody(dueReviewCount: reminderContext.dueReviewCount(at: date))
            content.sound = .default
            content.badge = 1
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date),
                repeats: false
            )
            
            center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)) { error in
                if let error = error {
                    AppLogger.error("Error scheduling notification", error: error, category: AppLogger.ui)
                }
            }
        }
    }
    
    func cancelDailyReminder() {
        // Remove only daily reminder notifications, not achievement notifications
        center.removePendingNotificationRequests(withIdentifiers: Self.reminderIds + Self.legacyReminderIds)
    }
    
    /// Даты напоминаний: сегодня — если занятий ещё не было и время не прошло, затем следующие дни
    static func reminderDates(
        now: Date,
        reminderTime: Date,
        isActiveToday: Bool,
        days: Int = reminderDays,
        calendar: Calendar = .current
    ) -> [Date] {
        let time = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let today = calendar.startOfDay(for: now)
        
        var result: [Date] = []
        var offset = 0
        while result.count < days {
            defer { offset += 1 }
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let date = calendar.date(bySettingHour: time.hour ?? 20, minute: time.minute ?? 0, second: 0, of: day) else {
                break
            }
            if offset == 0 && (isActiveToday || date <= now) {
                continue
            }
            result.append(date)
        }
        return result
    }
    
    /// Если к этому дню накопятся ошибки к повторению, напоминание говорит о них
    private func reminderBody(dueReviewCount: Int) -> String {
        guard dueReviewCount > 0 else {
            return localizationProvider.localizedString(for: "notification.body")
        }
        let key = PluralRules.key(
            for: "notification.body.review",
            count: dueReviewCount,
            language: localizationProvider.currentLanguage
        )
        return String(format: localizationProvider.localizedString(for: key), dueReviewCount)
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
                self.isPermissionDenied = settings.authorizationStatus == .denied
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
}
