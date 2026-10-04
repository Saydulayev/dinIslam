//
//  AppDependenciesProtocol.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

protocol AppDependenciesProtocol {
    var settingsManager: SettingsManager { get }
    var statsManager: StatsManager { get }
    var examStatisticsManager: ExamStatisticsManager { get }
    var adaptiveLearningEngine: AdaptiveLearningEngine { get }
    var profileManager: ProfileManager { get }
    var achievementManager: AchievementManager { get }
    var localizationProvider: LocalizationProviding { get }
    var quizUseCase: QuizUseCaseProtocol { get }
    var examUseCase: ExamUseCaseProtocol { get }
    var questionsRepository: EnhancedQuestionsRepositoryProtocol { get }
    var networkManager: NetworkManager { get }
    var hapticManager: HapticManager { get }
    var soundManager: SoundManager { get }
    var remoteQuestionsService: EnhancedRemoteQuestionsService { get }
    var notificationManager: NotificationManager { get }
    var questionPoolProgressManager: QuestionPoolProgressManaging { get }
}

