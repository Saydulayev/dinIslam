//
//  DefaultExamTimerManager.swift
//  dinIslam
//
//  Created by Saydulayev on 13.11.25.
//

import Foundation

@MainActor
final class DefaultExamTimerManager: ExamTimerManaging {
    /// Пока таймер идёт, остаток считается от момента окончания, иначе — сохранённый при остановке
    var timeRemaining: TimeInterval {
        get { deadline.map { max(0, $0.timeIntervalSinceNow) } ?? storedTimeRemaining }
        set { storedTimeRemaining = newValue }
    }
    var isTimerActive: Bool = false
    var questionStartTime: Date?
    /// Момент окончания времени: остаток считается от него, поэтому погрешность сна не накапливается
    private(set) var deadline: Date?
    
    private var storedTimeRemaining: TimeInterval = 0
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
            storedTimeRemaining = max(0, deadline.timeIntervalSinceNow)
        }
        deadline = nil
        isTimerActive = false
        timerTask?.cancel()
        timerTask = nil
        onTimeUpCallback = nil
    }
    
    /// Спим до момента окончания, а не опрашиваем остаток: экран считает секунды сам (TimelineView)
    private func runTimerLoop() async {
        while isTimerActive, let deadline {
            let remaining = deadline.timeIntervalSinceNow
            if remaining <= 0 {
                let callback = onTimeUpCallback
                storedTimeRemaining = 0
                isTimerActive = false
                self.deadline = nil
                callback?()
                return
            }
            do {
                try await Task.sleep(for: .seconds(remaining))
            } catch {
                return
            }
        }
    }
    
    nonisolated deinit {
        // Cancel timer task directly - safe to call from deinit
        timerTask?.cancel()
    }
}

