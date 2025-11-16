//
//  ExamViewModelCreating.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

protocol ExamViewModelCreating {
    func createExamViewModel(
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager,
        feedbackProvider: QuizFeedbackProviding?,
        settingsManager: SettingsManager?
    ) -> ExamViewModel
}

