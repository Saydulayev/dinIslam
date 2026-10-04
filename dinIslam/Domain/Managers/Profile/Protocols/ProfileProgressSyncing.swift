//
//  ProfileProgressSyncing.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

protocol ProfileProgressSyncing {
    func syncStatsUpdate(_ summary: QuizSessionSummary)
    func syncStatsReset()
    func syncStatsDidUpdate()
    func syncExamUpdate(_ summary: ExamSessionSummary)
    func syncExamReset()
}

