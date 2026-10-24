//
//  ExamViewModelCreating.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

protocol ExamViewModelCreating {
    func createExamViewModel(
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager,
        statsManager: StatsManager,
        achievementManager: AchievementManager,
        feedbackProvider: QuizFeedbackProviding?,
        settingsManager: SettingsManager?
    ) -> ExamViewModel
}

