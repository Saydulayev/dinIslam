//
//  DefaultExamTimerManager.swift
//  dinIslam
//
//  Created by Assistant on 13.11.25.
//

import Foundation

@MainActor
final class DefaultExamTimerManager: ExamTimerManaging {
    var timeRemaining: TimeInterval = 0
    var isTimerActive: Bool = false
    var questionStartTime: Date?
    
    private var timerTask: Task<Void, Never>?
    private var onTimeUpCallback: (@MainActor () -> Void)?
    /// Момент окончания времени: остаток считается от него, поэтому погрешность сна не накапливается
    private var deadline: Date?
    
    func startTimer(
        timeLimit: TimeInterval,
        onTimeUp: @escaping @MainActor () -> Void
    ) {
        stopTimer()
        
        // Если время уже установлено и меньше лимита, продолжаем с него (возобновление после паузы)
        // Иначе начинаем с полного лимита
        if timeRemaining <= 0 || timeRemaining >= timeLimit {
            timeRemaining = timeLimit
        }
        // Иначе оставляем текущее timeRemaining (возобновление после паузы)
        
        isTimerActive = true
        questionStartTime = Date()
        deadline = Date().addingTimeInterval(timeRemaining)
        onTimeUpCallback = onTimeUp
        
        timerTask = Task { [weak self] in
            guard let self else { return }
            await self.runTimerLoop()
        }
    }
    
    func stopTimer() {
        // Фиксируем остаток на момент остановки, чтобы после паузы продолжить с него
        if isTimerActive, let deadline {
            timeRemaining = max(0, deadline.timeIntervalSinceNow)
        }
        deadline = nil
        isTimerActive = false
        timerTask?.cancel()
        timerTask = nil
        onTimeUpCallback = nil
    }
    
    private func runTimerLoop() async {
        let interval: UInt64 = 100_000_000 // 0.1 секунды
        while isTimerActive && !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: interval)
            } catch {
                break
            }
            guard isTimerActive, let deadline else { break }
            timeRemaining = max(0, deadline.timeIntervalSinceNow)
            if timeRemaining <= 0 {
                let callback = onTimeUpCallback
                isTimerActive = false
                self.deadline = nil
                callback?()
                break
            }
        }
    }
    
    nonisolated deinit {
        // Cancel timer task directly - safe to call from deinit
        timerTask?.cancel()
    }
}

