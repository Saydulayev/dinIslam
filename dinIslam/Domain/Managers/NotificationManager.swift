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
    /// Серия дней на указанный момент, если до него занятий не будет
    func dayStreak(at date: Date) -> Int
}

/// О чём напоминание. Без давления: одно напоминание в день, спокойный тон
enum ReminderMessage: Equatable {
    /// Ошибки, срок повторения которых наступил к этому дню
    case review(count: Int)
    /// Серия — только в ближайшем напоминании: к дальним дням она может измениться
    case streak(days: Int)
    /// Последнее из запланированных: приложение не открывали неделю, дальше напоминаний нет
    case farewell
    /// Обычные тексты по очереди, чтобы не повторялись каждый день
    case general(variant: Int)
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
    /// С какой длины серия упоминается в напоминании
    static let streakMessageMinimum = 3
    static let generalMessageCount = 4
    
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
            hasPermission = granted
            isPermissionDenied = !granted
            if granted {
                isNotificationEnabled = true
                scheduleDailyReminder()
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
        
        for (index, (identifier, date)) in zip(Self.reminderIds, dates).enumerated() {
            let message = Self.reminderMessage(
                index: index,
                count: dates.count,
                date: date,
                dueReviewCount: reminderContext.dueReviewCount(at: date),
                dayStreak: reminderContext.dayStreak(at: date),
                calendar: calendar
            )
            let content = UNMutableNotificationContent()
            content.title = localizationProvider.localizedString(for: "notification.title")
            content.body = reminderBody(message)
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
    
    /// Текст напоминания по порядку: последнее перед паузой, ошибки к повторению,
    /// серия (в ближайшем), иначе обычный текст дня
    static func reminderMessage(
        index: Int,
        count: Int,
        date: Date,
        dueReviewCount: Int,
        dayStreak: Int,
        calendar: Calendar = .current
    ) -> ReminderMessage {
        if count > 1 && index == count - 1 {
            return .farewell
        }
        if dueReviewCount > 0 {
            return .review(count: dueReviewCount)
        }
        if index == 0 && dayStreak >= streakMessageMinimum {
            return .streak(days: dayStreak)
        }
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        return .general(variant: dayOfYear % generalMessageCount)
    }
    
    private func reminderBody(_ message: ReminderMessage) -> String {
        switch message {
        case .review(let count):
            return pluralText("notification.body.review", count: count)
        case .streak(let days):
            return pluralText("notification.body.streak", count: days)
        case .farewell:
            return localizationProvider.localizedString(for: "notification.body.farewell")
        case .general(let variant):
            if variant == 0 {
                return pluralText("notification.body.daily", count: DailyProgress.dailyGoalQuestions)
            }
            return localizationProvider.localizedString(for: "notification.body.general.\(variant)")
        }
    }
    
    private func pluralText(_ key: String, count: Int) -> String {
        let key = PluralRules.key(for: key, count: count, language: localizationProvider.currentLanguage)
        return String(format: localizationProvider.localizedString(for: key), count)
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
}
