//
//  DefaultExamViewModelFactory.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

final class DefaultExamViewModelFactory: ExamViewModelCreating {
    func createExamViewModel(
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager,
        statsManager: StatsManager,
        achievementManager: AchievementManager,
        feedbackProvider: QuizFeedbackProviding? = nil,
        settingsManager: SettingsManager? = nil
    ) -> ExamViewModel {
        let timerManager = DefaultExamTimerManager()
        let navigationCoordinator = DefaultExamNavigationCoordinator()
        let statisticsCalculator = DefaultExamStatisticsCalculator()
        return ExamViewModel(
            examUseCase: examUseCase,
            examStatisticsManager: examStatisticsManager,
            statisticsRecorder: DefaultQuizStatisticsRecorder(statsManager: statsManager),
            achievementChecker: DefaultQuizAchievementChecker(achievementManager: achievementManager),
            feedbackProvider: feedbackProvider,
            timerManager: timerManager,
            navigationCoordinator: navigationCoordinator,
            statisticsCalculator: statisticsCalculator,
            settingsManager: settingsManager
        )
    }
}

