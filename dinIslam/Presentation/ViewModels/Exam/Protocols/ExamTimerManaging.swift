//
//  ExamTimerManaging.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

@MainActor
protocol ExamTimerManaging {
    var timeRemaining: TimeInterval { get set }
    var isTimerActive: Bool { get set }
    var questionStartTime: Date? { get set }
    
    func startTimer(
        timeLimit: TimeInterval,
        onTimeUp: @escaping @MainActor () -> Void
    )
    func stopTimer()
}

