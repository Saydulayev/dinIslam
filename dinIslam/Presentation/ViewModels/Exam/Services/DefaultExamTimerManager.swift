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
        onTimeUpCallback = onTimeUp
        
        timerTask = Task { [weak self] in
            guard let self else { return }
            await self.runTimerLoop()
        }
    }
    
    func stopTimer() {
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
            guard isTimerActive else { break }
            timeRemaining = max(0, timeRemaining - 0.1)
            if timeRemaining <= 0 {
                timeRemaining = 0
                await MainActor.run {
                    self.isTimerActive = false
                    self.onTimeUpCallback?()
                }
                break
            }
        }
    }
    
    nonisolated deinit {
        // Cancel timer task directly - safe to call from deinit
        timerTask?.cancel()
    }
}

