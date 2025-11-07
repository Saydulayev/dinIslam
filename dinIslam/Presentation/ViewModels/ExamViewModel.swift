//
//  ExamViewModel.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Observation
import UIKit
import AudioToolbox

@MainActor
@Observable
class ExamViewModel {
    // MARK: - Properties
    private let examUseCase: ExamUseCaseProtocol
    private let examStatisticsManager: ExamStatisticsManager
    private let hapticManager: HapticManager
    private let soundManager: SoundManager
    
    var state: ExamState = .idle
    var configuration: ExamConfiguration = .default
    var questions: [Question] = []
    var currentQuestionIndex: Int = 0
    var answers: [String: ExamAnswer] = [:]
    var examResult: ExamResult?
    var errorMessage: String?
    var isLoading: Bool = false
    
    // Timer properties
    var timeRemaining: TimeInterval = 0
    var isTimerActive: Bool = false
    private var timerTask: Task<Void, Never>?
    private var questionStartTime: Date?
    
    // Progress tracking
    private var examStartTime: Date?
    private var totalTimeSpent: TimeInterval = 0
    private var nextQuestionTask: Task<Void, Never>?
    
    // MARK: - Computed Properties
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }
    
    var isLastQuestion: Bool {
        return currentQuestionIndex == questions.count - 1
    }
    
    var answeredQuestionsCount: Int {
        return answers.values.filter { !$0.isSkipped && !$0.isTimeExpired }.count
    }
    
    var skippedQuestionsCount: Int {
        return answers.values.filter { $0.isSkipped || $0.isTimeExpired }.count
    }
    
    var correctAnswersCount: Int {
        return answers.values.filter { answer in
            guard let question = questions.first(where: { $0.id == answer.questionId }),
                  let selectedIndex = answer.selectedAnswerIndex,
                  !answer.isSkipped && !answer.isTimeExpired else {
                return false
            }
            return selectedIndex == question.correctIndex
        }.count
    }
    
    var timeRemainingFormatted: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var canSkipQuestion: Bool {
        return configuration.allowSkip
    }
    
    var canSubmitExam: Bool {
        return answeredQuestionsCount > 0
    }
    
    // MARK: - Initialization
    init(examUseCase: ExamUseCaseProtocol, examStatisticsManager: ExamStatisticsManager, settingsManager: SettingsManager) {
        self.examUseCase = examUseCase
        self.examStatisticsManager = examStatisticsManager
        self.hapticManager = HapticManager(settingsManager: settingsManager)
        self.soundManager = SoundManager(settingsManager: settingsManager)
    }
    
    // MARK: - Public Methods
    func startExam(configuration: ExamConfiguration, language: String) async {
        self.configuration = configuration
        state = .active(.loading)
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedQuestions = try await examUseCase.startExam(configuration: configuration, language: language)
            
            questions = loadedQuestions
            currentQuestionIndex = 0
            answers.removeAll()
            examStartTime = Date()
            totalTimeSpent = 0
            
            // Start first question timer
            startQuestionTimer()
            
            state = .active(.playing)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            state = .error(.networkError)
            isLoading = false
        }
    }
    
    func selectAnswer(at index: Int) {
        guard let currentQuestion = currentQuestion,
              state == .active(.playing) else { return }
        
        // Stop timer
        stopQuestionTimer()
        
        // Calculate time spent on this question
        let timeSpent = questionStartTime?.timeIntervalSinceNow.magnitude ?? 0
        
        // Create answer
        let answer = ExamAnswer(
            questionId: currentQuestion.id,
            selectedAnswerIndex: index,
            correctAnswerIndex: currentQuestion.correctIndex,
            timeSpent: timeSpent
        )
        
        answers[currentQuestion.id] = answer
        
        // Provide feedback
        let isCorrect = index == currentQuestion.correctIndex
        if isCorrect {
            hapticManager.success()
            soundManager.playSuccessSound()
        } else {
            hapticManager.error()
            soundManager.playErrorSound()
        }
        
        // Move to next question after brief delay
        nextQuestionTask?.cancel()
        nextQuestionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            self?.nextQuestion()
        }
    }
    
    func skipQuestion() {
        guard canSkipQuestion,
              let currentQuestion = currentQuestion,
              state == .active(.playing) else { return }
        
        // Stop timer
        stopQuestionTimer()
        
        // Calculate time spent
        let timeSpent = questionStartTime?.timeIntervalSinceNow.magnitude ?? 0
        
        // Create skipped answer
        let answer = ExamAnswer(
            questionId: currentQuestion.id,
            correctAnswerIndex: currentQuestion.correctIndex,
            isSkipped: true,
            timeSpent: timeSpent
        )
        
        answers[currentQuestion.id] = answer
        
        // Provide feedback
        hapticManager.selectionChanged()
        soundManager.playSelectionSound()
        
        // Move to next question
        nextQuestionTask?.cancel()
        nextQuestion()
    }
    
    func nextQuestion() {
        if isLastQuestion {
            finishExam()
        } else {
            currentQuestionIndex += 1
            startQuestionTimer()
        }
    }
    
    func pauseExam() {
        guard state == .active(.playing) else { return }
        
        stopQuestionTimer()
        state = .active(.paused)
        hapticManager.selectionChanged()
    }
    
    func resumeExam() {
        guard state == .active(.paused) else { return }
        
        startQuestionTimer()
        state = .active(.playing)
        hapticManager.selectionChanged()
    }
    
    func finishExam() {
        stopQuestionTimer()
        
        // Calculate total time spent
        if let startTime = examStartTime {
            totalTimeSpent = Date().timeIntervalSince(startTime)
        }
        
        // Calculate exam result
        examResult = examUseCase.calculateExamResult(
            questions: questions,
            answers: answers,
            configuration: configuration,
            totalTimeSpent: totalTimeSpent
        )
        
        // Update statistics
        if let result = examResult {
            examStatisticsManager.updateStatistics(with: result)
        }
        
        state = .completed(.finished)
        
        // Provide completion feedback
        hapticManager.success()
        soundManager.playSuccessSound()
    }
    
    func stopExam() {
        stopQuestionTimer()
        nextQuestionTask?.cancel()
        
        // Calculate total time spent
        if let startTime = examStartTime {
            totalTimeSpent = Date().timeIntervalSince(startTime)
        }
        
        // Calculate exam result
        examResult = examUseCase.calculateExamResult(
            questions: questions,
            answers: answers,
            configuration: configuration,
            totalTimeSpent: totalTimeSpent
        )
        
        // Update statistics
        if let result = examResult {
            examStatisticsManager.updateStatistics(with: result)
        }
        
        state = .completed(.manuallyStopped)
        hapticManager.selectionChanged()
    }
    
    func restartExam() {
        state = .idle
        questions = []
        currentQuestionIndex = 0
        answers.removeAll()
        examResult = nil
        errorMessage = nil
        timeRemaining = 0
        isTimerActive = false
        stopQuestionTimer()
        nextQuestionTask?.cancel()
        nextQuestionTask = nil
    }
    
    // MARK: - Timer Methods
    private func startQuestionTimer() {
        guard currentQuestion != nil else { return }
        
        stopQuestionTimer()
        
        timeRemaining = configuration.timePerQuestion
        isTimerActive = true
        questionStartTime = Date()
        
        timerTask = Task { [weak self] in
            guard let self else { return }
            await self.runTimerLoop()
        }
    }
    
    private func stopQuestionTimer() {
        isTimerActive = false
        timerTask?.cancel()
        timerTask = nil
    }
    
    @MainActor
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
                handleTimeUp()
                break
            }
        }
    }
    
    private func handleTimeUp() {
        guard let currentQuestion = currentQuestion else { return }
        
        stopQuestionTimer()
        
        // Calculate time spent
        let timeSpent = questionStartTime?.timeIntervalSinceNow.magnitude ?? 0
        
        // Create time expired answer
        let answer = ExamAnswer(
            questionId: currentQuestion.id,
            correctAnswerIndex: currentQuestion.correctIndex,
            timeSpent: timeSpent,
            isTimeExpired: true
        )
        
        answers[currentQuestion.id] = answer
        
        // Provide feedback
        hapticManager.error()
        soundManager.playErrorSound()
        
        // Show time up state briefly
        state = .active(.timeUp)
        
        // Auto-submit if enabled, otherwise move to next question
        nextQuestionTask?.cancel()
        nextQuestionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            guard let self else { return }
            
            if self.configuration.autoSubmit {
                if self.isLastQuestion {
                    self.finishExam()
                } else {
                    self.currentQuestionIndex += 1
                    self.state = .active(.playing)
                    self.startQuestionTimer()
                }
            } else {
                self.nextQuestion()
            }
        }
    }
    
    @MainActor
    deinit {
        stopQuestionTimer()
        nextQuestionTask?.cancel()
    }
}
