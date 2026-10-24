//
//  AppDependencies.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

struct AppDependencies: AppDependenciesProtocol {
    let settingsManager: SettingsManager
    let statsManager: StatsManager
    let examStatisticsManager: ExamStatisticsManager
    let adaptiveLearningEngine: AdaptiveLearningEngine
    let profileManager: ProfileManager
    let achievementManager: AchievementManager
    let localizationProvider: LocalizationProviding
    let quizUseCase: QuizUseCaseProtocol
    let examUseCase: ExamUseCaseProtocol
    let questionsRepository: EnhancedQuestionsRepositoryProtocol
    let networkManager: NetworkManager
    let hapticManager: HapticManager
    let soundManager: SoundManager
    let remoteQuestionsService: EnhancedRemoteQuestionsService
    let notificationManager: NotificationManager
    let questionPoolProgressManager: QuestionPoolProgressManaging
    
    init(userDefaults: UserDefaults = .standard) {
        // Initialize localization provider first
        self.localizationProvider = LocalizationManager()
        
        // Initialize notification manager with localization provider (needed for achievement manager)
        self.notificationManager = NotificationManager(localizationProvider: localizationProvider)
        
        // Initialize settings manager with localization provider
        self.settingsManager = SettingsManager(
            localizationProvider: localizationProvider
        )
        
        // Initialize core services
        self.adaptiveLearningEngine = AdaptiveLearningEngine()
        
        // Initialize stats managers with injected UserDefaults
        self.statsManager = StatsManager(userDefaults: userDefaults)
        notificationManager.reminderContext = statsManager
        self.examStatisticsManager = ExamStatisticsManager()
        
        // Initialize achievement manager
        self.achievementManager = AchievementManager(
            notificationManager: notificationManager,
            localizationProvider: localizationProvider
        )
        
        // Initialize question pool progress manager with injected UserDefaults
        self.questionPoolProgressManager = DefaultQuestionPoolProgressManager(userDefaults: userDefaults)
        
        // Initialize profile manager
        // Profile manager syncs all of the above with iCloud
        self.profileManager = ProfileManager(
            statsManager: statsManager,
            examStatisticsManager: examStatisticsManager,
            achievementManager: achievementManager,
            questionPoolProgressManager: questionPoolProgressManager
        )
        
        // Initialize questions loading (GitHub → cache → bundled)
        EnhancedRemoteQuestionsService.removeLegacyCache(from: userDefaults)
        // One instance for the whole app (quiz, exam, enhanced quiz, profile and stats screens)
        let networkManager = NetworkManager()
        let remoteQuestionsService = EnhancedRemoteQuestionsService(networkManager: networkManager)
        self.networkManager = networkManager
        self.remoteQuestionsService = remoteQuestionsService
        self.questionsRepository = EnhancedQuestionsRepository(remoteService: remoteQuestionsService)
        
        // Initialize question selection strategies
        let adaptiveStrategy = AdaptiveQuestionSelectionStrategy(adaptiveEngine: adaptiveLearningEngine)
        let fallbackStrategy = FallbackQuestionSelectionStrategy()
        
        // Initialize use cases
        self.quizUseCase = QuizUseCase(
            questionsRepository: questionsRepository,
            topicStatsProvider: statsManager,
            questionSelectionStrategy: adaptiveStrategy,
            fallbackStrategy: fallbackStrategy,
            questionPoolProgressManager: questionPoolProgressManager
        )
        
        self.examUseCase = ExamUseCase(
            questionsRepository: questionsRepository,
            examStatisticsManager: examStatisticsManager
        )
        
        // Initialize managers
        self.hapticManager = HapticManager(settingsManager: settingsManager)
        self.soundManager = SoundManager(settingsManager: settingsManager)
    }
}

