//
//  dinIslamApp.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import SwiftUI

// MARK: - Environment Keys
private struct StatsManagerKey: EnvironmentKey {
    static let defaultValue: StatsManager? = nil
}

private struct SettingsManagerKey: EnvironmentKey {
    static let defaultValue: SettingsManager? = nil
}

private struct ProfileManagerKey: EnvironmentKey {
    static let defaultValue: ProfileManager? = nil
}

private struct LocalizationProviderKey: EnvironmentKey {
    static let defaultValue: LocalizationProviding? = nil
}

private struct AchievementManagerKey: EnvironmentKey {
    static let defaultValue: AchievementManager? = nil
}

private struct RemoteQuestionsServiceKey: EnvironmentKey {
    static let defaultValue: EnhancedRemoteQuestionsService? = nil
}

private struct NotificationManagerKey: EnvironmentKey {
    static let defaultValue: NotificationManager? = nil
}

private struct QuestionPoolProgressManagerKey: EnvironmentKey {
    static let defaultValue: QuestionPoolProgressManaging? = nil
}

/// Запасные значения окружения для превью: в приложении все значения задаёт dinIslamApp.
/// Создаются один раз, а не при каждом чтении окружения — иначе каждый экран получал бы свой менеджер
private enum EnvironmentFallback {
    static let localizationProvider: LocalizationProviding = LocalizationManager()
    static let notificationManager = NotificationManager(localizationProvider: localizationProvider)
    static let achievementManager = AchievementManager(
        notificationManager: notificationManager,
        localizationProvider: localizationProvider
    )
    static let statsManager = StatsManager()
    static let settingsManager = SettingsManager(localizationProvider: localizationProvider)
    static let profileManager = ProfileManager(
        statsManager: statsManager,
        examStatisticsManager: ExamStatisticsManager(),
        achievementManager: achievementManager
    )
    static let remoteQuestionsService = EnhancedRemoteQuestionsService()
    static let questionPoolProgressManager: QuestionPoolProgressManaging = DefaultQuestionPoolProgressManager()
}

extension EnvironmentValues {
    var localizationProvider: LocalizationProviding {
        get { 
            self[LocalizationProviderKey.self] ?? EnvironmentFallback.localizationProvider
        }
        set { 
            self[LocalizationProviderKey.self] = newValue 
        }
    }
    
    var achievementManager: AchievementManager {
        get { 
            self[AchievementManagerKey.self] ?? EnvironmentFallback.achievementManager
        }
        set { 
            self[AchievementManagerKey.self] = newValue 
        }
    }
}

extension EnvironmentValues {
    var statsManager: StatsManager {
        get { 
            self[StatsManagerKey.self] ?? EnvironmentFallback.statsManager
        }
        set { 
            self[StatsManagerKey.self] = newValue 
        }
    }

    var settingsManager: SettingsManager {
        get { 
            self[SettingsManagerKey.self] ?? EnvironmentFallback.settingsManager
        }
        set { 
            self[SettingsManagerKey.self] = newValue 
        }
    }

    var profileManager: ProfileManager {
        get { 
            self[ProfileManagerKey.self] ?? EnvironmentFallback.profileManager
        }
        set { 
            self[ProfileManagerKey.self] = newValue 
        }
    }
    
    var remoteQuestionsService: EnhancedRemoteQuestionsService {
        get {
            self[RemoteQuestionsServiceKey.self] ?? EnvironmentFallback.remoteQuestionsService
        }
        set {
            self[RemoteQuestionsServiceKey.self] = newValue
        }
    }
    
    var notificationManager: NotificationManager {
        get {
            self[NotificationManagerKey.self] ?? EnvironmentFallback.notificationManager
        }
        set {
            self[NotificationManagerKey.self] = newValue
        }
    }
    
    var questionPoolProgressManager: QuestionPoolProgressManaging {
        get {
            self[QuestionPoolProgressManagerKey.self] ?? EnvironmentFallback.questionPoolProgressManager
        }
        set {
            self[QuestionPoolProgressManagerKey.self] = newValue
        }
    }
}

@main
struct dinIslamApp: App {
    private let dependencies: AppDependencies
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Create dependencies
        self.dependencies = AppDependencies()
        
        // Set global localization provider for use in enum properties and String extensions
        GlobalLocalizationProvider.setInstance(dependencies.localizationProvider)
    }
    
    var body: some Scene {
        WindowGroup {
            StartView(
                quizUseCase: dependencies.quizUseCase,
                statsManager: dependencies.statsManager,
                settingsManager: dependencies.settingsManager,
                profileManager: dependencies.profileManager,
                examUseCase: dependencies.examUseCase,
                examStatisticsManager: dependencies.examStatisticsManager,
                questionsRepository: dependencies.questionsRepository,
                achievementManager: dependencies.achievementManager,
                questionPoolProgressManager: dependencies.questionPoolProgressManager
            )
            // Set achievementManager first to ensure it's available before any views access it
            .environment(\.achievementManager, dependencies.achievementManager)
            .environment(\.notificationManager, dependencies.notificationManager)
            .environment(\.localizationProvider, dependencies.localizationProvider)
            .environment(\.settingsManager, dependencies.settingsManager)
            .environment(\.statsManager, dependencies.statsManager)
            .environment(\.profileManager, dependencies.profileManager)
            .environment(\.remoteQuestionsService, dependencies.remoteQuestionsService)
            .environment(\.questionPoolProgressManager, dependencies.questionPoolProgressManager)
            .preferredColorScheme(.dark)
            // Напоминания и виджет: данные могли прийти из iCloud без уведомления об изменении — обновляем при уходе в фон
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    dependencies.notificationManager.scheduleDailyReminder()
                    dependencies.widgetUpdater.update()
                }
            }
            // Тексты напоминаний и виджета — на новом языке
            .onChange(of: dependencies.settingsManager.settings.language) { _, _ in
                dependencies.notificationManager.scheduleDailyReminder()
                dependencies.widgetUpdater.update()
            }
        }
    }
}
