//
//  AppDependencies.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
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
    let questionsRepository: QuestionsRepositoryProtocol
    let hapticManager: HapticManager
    let soundManager: SoundManager
    let remoteQuestionsService: RemoteQuestionsService
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
        self.examStatisticsManager = ExamStatisticsManager()
        
        // Initialize achievement manager
        self.achievementManager = AchievementManager(
            notificationManager: notificationManager,
            localizationProvider: localizationProvider
        )
        
        // Initialize profile manager
        self.profileManager = ProfileManager(
            adaptiveEngine: adaptiveLearningEngine,
            statsManager: statsManager,
            examStatisticsManager: examStatisticsManager
        )
        
        // Set up synchronization: ProfileManager implements ProfileProgressSyncing
        statsManager.setProfileProgressSyncer(profileManager)
        examStatisticsManager.setProfileProgressSyncer(profileManager)
        
        // Initialize repositories
        self.questionsRepository = QuestionsRepository()
        
        // Initialize question pool progress manager with injected UserDefaults
        self.questionPoolProgressManager = DefaultQuestionPoolProgressManager(userDefaults: userDefaults)
        
        // Initialize question selection strategies
        let adaptiveStrategy = AdaptiveQuestionSelectionStrategy(adaptiveEngine: adaptiveLearningEngine)
        let fallbackStrategy = FallbackQuestionSelectionStrategy()
        
        // Initialize use cases
        self.quizUseCase = QuizUseCase(
            questionsRepository: questionsRepository,
            profileProgressProvider: profileManager, // ProfileManager implements ProfileProgressProviding
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
        self.remoteQuestionsService = RemoteQuestionsService()
    }
}

