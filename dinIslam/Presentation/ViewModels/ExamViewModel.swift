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
    private let feedbackProvider: QuizFeedbackProviding
    private var timerManager: ExamTimerManaging
    private let navigationCoordinator: ExamNavigationCoordinating
    private let statisticsCalculator: ExamStatisticsCalculating
    
    var state: ExamState = .idle
    var configuration: ExamConfiguration = .default
    var questions: [Question] = []
    var currentQuestionIndex: Int = 0
    var answers: [String: ExamAnswer] = [:]
    var examResult: ExamResult?
    var errorMessage: String?
    var isLoading: Bool = false
    
    // Timer properties (delegated to timerManager)
    var timeRemaining: TimeInterval {
        get { displayedTimeRemaining }
        set { 
            timerManager.timeRemaining = newValue
            displayedTimeRemaining = newValue
        }
    }
    var isTimerActive: Bool {
        get { timerManager.isTimerActive }
        set { timerManager.isTimerActive = newValue }
    }
    
    // Progress tracking
    private var examStartTime: Date?
    private var totalTimeSpent: TimeInterval = 0
    private var nextQuestionTask: Task<Void, Never>?
    // Язык последнего запуска — нужен для пересдачи с той же конфигурацией
    private var lastLanguage: String = "ru"

    // Timer update tracking for SwiftUI
    private var displayedTimeRemaining: TimeInterval = 0
    private var timerUpdateTask: Task<Void, Never>?
    
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
        statisticsCalculator.calculateAnsweredCount(answers: answers)
    }
    
    var skippedQuestionsCount: Int {
        statisticsCalculator.calculateSkippedAnswers(answers: answers)
    }
    
    var correctAnswersCount: Int {
        statisticsCalculator.calculateCorrectAnswers(
            answers: answers,
            questions: questions
        )
    }
    
    var timeRemainingFormatted: String {
        // Округляем вверх: «00:00» появляется только когда время действительно вышло
        let totalSeconds = Int(timeRemaining.rounded(.up))
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
    
    /// Насколько мало осталось времени — пороги считаются от лимита на вопрос
    var timerUrgency: ExamTimerUrgency {
        let limit = configuration.timePerQuestion
        if timeRemaining <= min(10, limit / 4) {
            return .critical
        } else if timeRemaining <= min(20, limit / 2) {
            return .warning
        }
        return .normal
    }
    
    var canSkipQuestion: Bool {
        return configuration.allowSkip
    }
    
    var canSubmitExam: Bool {
        return answeredQuestionsCount > 0
    }
    
    // MARK: - Initialization
    init(
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager,
        feedbackProvider: QuizFeedbackProviding? = nil,
        timerManager: ExamTimerManaging? = nil,
        navigationCoordinator: ExamNavigationCoordinating? = nil,
        statisticsCalculator: ExamStatisticsCalculating? = nil,
        settingsManager: SettingsManager? = nil
    ) {
        self.examUseCase = examUseCase
        self.examStatisticsManager = examStatisticsManager
        self.timerManager = timerManager ?? DefaultExamTimerManager()
        self.navigationCoordinator = navigationCoordinator ?? DefaultExamNavigationCoordinator()
        self.statisticsCalculator = statisticsCalculator ?? DefaultExamStatisticsCalculator()
        
        // Initialize feedback provider
        if let feedbackProvider = feedbackProvider {
            self.feedbackProvider = feedbackProvider
        } else if let settingsManager = settingsManager {
            let hapticManager = HapticManager(settingsManager: settingsManager)
            let soundManager = SoundManager(settingsManager: settingsManager)
            self.feedbackProvider = DefaultQuizFeedbackProvider(
                hapticManager: hapticManager,
                soundManager: soundManager
            )
        } else {
            // Fallback: create defaults without settings manager
            self.feedbackProvider = DefaultQuizFeedbackProvider(
                hapticManager: HapticManager(),
                soundManager: SoundManager()
            )
        }
    }
    
    convenience init(examUseCase: ExamUseCaseProtocol, examStatisticsManager: ExamStatisticsManager, settingsManager: SettingsManager) {
        let hapticManager = HapticManager(settingsManager: settingsManager)
        let soundManager = SoundManager(settingsManager: settingsManager)
        let feedbackProvider = DefaultQuizFeedbackProvider(
            hapticManager: hapticManager,
            soundManager: soundManager
        )
        let statisticsCalculator = DefaultExamStatisticsCalculator()
        self.init(
            examUseCase: examUseCase,
            examStatisticsManager: examStatisticsManager,
            feedbackProvider: feedbackProvider,
            statisticsCalculator: statisticsCalculator,
            settingsManager: settingsManager
        )
    }
    
    // MARK: - Public Methods
    func startExam(configuration: ExamConfiguration, language: String) async {
        self.configuration = configuration
        lastLanguage = language
        state = .active(.loading)
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedQuestions = try await examUseCase.startExam(configuration: configuration, language: language)
            
            // Без вопросов экзамен не начинаем — иначе экран показывает «1 / 0»
            guard !loadedQuestions.isEmpty else {
                errorMessage = "error.emptyData".localized
                state = .error(.dataError)
                isLoading = false
                return
            }
            
            questions = loadedQuestions
            currentQuestionIndex = 0
            answers.removeAll()
            examStartTime = Date()
            totalTimeSpent = 0
            
            // Сбрасываем время для первого вопроса
            timerManager.timeRemaining = 0
            displayedTimeRemaining = 0
            
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
        let timeSpent = timerManager.questionStartTime?.timeIntervalSinceNow.magnitude ?? 0
        
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
        feedbackProvider.answerSelected(isCorrect: isCorrect)
        
        // Move to next question after brief delay
        nextQuestionTask?.cancel()
        nextQuestionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            // try? глушит CancellationError, поэтому отмену проверяем явно
            guard !Task.isCancelled else { return }
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
        let timeSpent = timerManager.questionStartTime?.timeIntervalSinceNow.magnitude ?? 0
        
        // Create skipped answer
        let answer = ExamAnswer(
            questionId: currentQuestion.id,
            correctAnswerIndex: currentQuestion.correctIndex,
            isSkipped: true,
            timeSpent: timeSpent
        )
        
        answers[currentQuestion.id] = answer
        
        // Provide feedback
        feedbackProvider.questionSkipped()
        
        // Move to next question
        nextQuestionTask?.cancel()
        nextQuestion()
    }
    
    func nextQuestion() {
        if isLastQuestion {
            finishExam()
        } else {
            currentQuestionIndex += 1
            // Сбрасываем время для нового вопроса
            timerManager.timeRemaining = 0
            displayedTimeRemaining = 0
            startQuestionTimer()
        }
    }
    
    func pauseExam() {
        guard state == .active(.playing) else { return }
        
        stopQuestionTimer()
        state = .active(.paused)
        feedbackProvider.questionPaused()
    }
    
    func resumeExam() {
        guard state == .active(.paused) else { return }
        
        startQuestionTimer()
        state = .active(.playing)
        feedbackProvider.questionResumed()
    }
    
    func finishExam() {
        // Отложенный переход к следующему вопросу не должен сработать после завершения
        nextQuestionTask?.cancel()
        nextQuestionTask = nil
        if case .completed = state { return }

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
        feedbackProvider.quizCompleted(success: true)
        
        // Navigate to results
        navigationCoordinator.showResults()
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
        feedbackProvider.quizCompleted(success: false)
        
        // Navigate to exit
        navigationCoordinator.exitExam()
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
        
        // Navigate to restart
        navigationCoordinator.restartExam()
    }

    /// Пересдача: новый набор вопросов с той же конфигурацией и языком
    func retake() async {
        restartExam()
        await startExam(configuration: configuration, language: lastLanguage)
    }
    
    // MARK: - Timer Methods
    private func startQuestionTimer() {
        guard currentQuestion != nil else { return }
        
        // startTimer() автоматически использует текущее timeRemaining если оно > 0 (возобновление после паузы)
        // или устанавливает полное время если timeRemaining <= 0 (новый вопрос)
        timerManager.startTimer(
            timeLimit: configuration.timePerQuestion,
            onTimeUp: { [weak self] in
                self?.handleTimeUp()
            }
        )
        
        // Sync displayed time
        displayedTimeRemaining = timerManager.timeRemaining
        
        // Обновляем экран, когда меняется показываемая секунда; частый опрос убирает рывки и пропуски секунд
        timerUpdateTask?.cancel()
        timerUpdateTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled && self.timerManager.isTimerActive {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                guard !Task.isCancelled else { break }
                let remaining = self.timerManager.timeRemaining
                if remaining.rounded(.up) != self.displayedTimeRemaining.rounded(.up) {
                    self.displayedTimeRemaining = remaining
                }
            }
        }
    }
    
    private func stopQuestionTimer() {
        timerManager.stopTimer()
        timerUpdateTask?.cancel()
        timerUpdateTask = nil
        displayedTimeRemaining = timerManager.timeRemaining
    }
    
    private func handleTimeUp() {
        guard let currentQuestion = currentQuestion else { return }
        
        stopQuestionTimer()
        
        // Calculate time spent
        let timeSpent = timerManager.questionStartTime?.timeIntervalSinceNow.magnitude ?? 0
        
        // Create time expired answer
        let answer = ExamAnswer(
            questionId: currentQuestion.id,
            correctAnswerIndex: currentQuestion.correctIndex,
            timeSpent: timeSpent,
            isTimeExpired: true
        )
        
        answers[currentQuestion.id] = answer
        
        // Provide feedback
        feedbackProvider.answerSelected(isCorrect: false)
        
        // Show time up state briefly
        state = .active(.timeUp)
        
        // Переходим к следующему вопросу (на последнем — завершаем экзамен)
        nextQuestionTask?.cancel()
        nextQuestionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds, как после ответа
            guard let self, !Task.isCancelled else { return }
            // Возвращаемся из .timeUp, иначе ответы на следующие вопросы блокируются
            self.state = .active(.playing)
            self.nextQuestion()
        }
    }
    
    @MainActor
    deinit {
        timerManager.stopTimer()
        nextQuestionTask?.cancel()
        timerUpdateTask?.cancel()
    }
}
