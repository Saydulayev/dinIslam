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
    private let statisticsRecorder: QuizStatisticsRecording
    private let achievementChecker: QuizAchievementChecking
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
    /// Достижения, открытые этим экзаменом: показываются на экране результата
    var newAchievements: [Achievement] = []
    var errorMessage: String?
    var isLoading: Bool = false
    
    /// Когда истекает время на текущий вопрос; nil — таймер остановлен (пауза, ответ дан)
    private(set) var questionDeadline: Date?
    /// Остаток, пока таймер остановлен
    private var stoppedTimeRemaining: TimeInterval = 0
    
    var timeRemaining: TimeInterval {
        get { timeRemaining(at: Date()) }
        set {
            timerManager.timeRemaining = newValue
            stoppedTimeRemaining = newValue
            questionDeadline = nil
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
    
    // MARK: - Computed Properties
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    /// Доля вопросов с ответом, пропуском или истёкшим временем: после последнего полоса заполнена до конца
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        let isCurrentAnswered = currentQuestion.map { answers[$0.id] != nil } ?? false
        return Double(currentQuestionIndex + (isCurrentAnswered ? 1 : 0)) / Double(questions.count)
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
        timeRemainingFormatted(at: Date())
    }
    
    var timerUrgency: ExamTimerUrgency {
        timerUrgency(at: Date())
    }
    
    /// Экран спрашивает остаток на момент очередного кадра TimelineView
    func timeRemaining(at date: Date) -> TimeInterval {
        guard let questionDeadline else { return stoppedTimeRemaining }
        return max(0, questionDeadline.timeIntervalSince(date))
    }
    
    func timeRemainingFormatted(at date: Date) -> String {
        // Округляем вверх: «00:00» появляется только когда время действительно вышло
        let totalSeconds = Int(timeRemaining(at: date).rounded(.up))
        return String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
    
    /// Насколько мало осталось времени — пороги считаются от лимита на вопрос
    func timerUrgency(at date: Date) -> ExamTimerUrgency {
        let limit = configuration.timePerQuestion
        let remaining = timeRemaining(at: date)
        if remaining <= min(10, limit / 4) {
            return .critical
        } else if remaining <= min(20, limit / 2) {
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

    /// Пауза только пока на вопрос не ответили: после ответа уже идёт переход к следующему вопросу
    var canPause: Bool {
        guard state == .active(.playing), let currentQuestion else { return false }
        return answers[currentQuestion.id] == nil
    }
    
    // MARK: - Initialization
    init(
        examUseCase: ExamUseCaseProtocol,
        examStatisticsManager: ExamStatisticsManager,
        statisticsRecorder: QuizStatisticsRecording,
        achievementChecker: QuizAchievementChecking,
        feedbackProvider: QuizFeedbackProviding? = nil,
        timerManager: ExamTimerManaging? = nil,
        navigationCoordinator: ExamNavigationCoordinating? = nil,
        statisticsCalculator: ExamStatisticsCalculating? = nil,
        settingsManager: SettingsManager? = nil
    ) {
        self.examUseCase = examUseCase
        self.examStatisticsManager = examStatisticsManager
        self.statisticsRecorder = statisticsRecorder
        self.achievementChecker = achievementChecker
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
            stoppedTimeRemaining = 0
            
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
            stoppedTimeRemaining = 0
            startQuestionTimer()
        }
    }
    
    func pauseExam() {
        guard canPause else { return }
        
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
        completeExam()
        
        state = .completed(.finished)
        
        feedbackProvider.quizCompleted(success: examResult?.isPassed ?? false)
        
        // Navigate to results
        navigationCoordinator.showResults()
    }
    
    func stopExam() {
        stopQuestionTimer()
        nextQuestionTask?.cancel()
        if case .completed = state { return }
        completeExam()
        
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
        newAchievements = []
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
    
    // MARK: - Recording
    
    /// Считает результат и сохраняет его: статистику экзаменов и ответы — в общую статистику
    private func completeExam() {
        if let startTime = examStartTime {
            totalTimeSpent = Date().timeIntervalSince(startTime)
        }
        
        let result = examUseCase.calculateExamResult(
            questions: questions,
            answers: answers,
            configuration: configuration,
            totalTimeSpent: totalTimeSpent
        )
        examResult = result
        
        // Экзамен, остановленный до первого ответа, не сохраняется
        guard !answers.isEmpty else { return }
        
        examStatisticsManager.updateStatistics(with: result)
        recordAnswers(completedAt: result.completedAt)
    }
    
    /// Ответы экзамена — в статистику по темам, повторение ошибок, серию дней и достижения.
    /// Пропуск и истёкшее время считаются неверным ответом. Вопросы, до которых не дошли, не учитываются.
    private func recordAnswers(completedAt: Date) {
        let outcomes = questions.compactMap { question -> QuizQuestionOutcome? in
            guard let answer = answers[question.id] else { return nil }
            return QuizQuestionOutcome(
                questionId: question.id,
                category: question.category,
                difficulty: question.difficulty,
                isCorrect: answer.isCorrect
            )
        }
        let correct = outcomes.filter(\.isCorrect).count
        
        // Экзамен — не викторина: в историю викторин, серию побед и их достижения он не входит
        let summary = QuizSessionSummary(
            correctAnswers: correct,
            totalQuestions: outcomes.count,
            percentage: Double(correct) / Double(outcomes.count) * 100,
            duration: totalTimeSpent,
            completedAt: completedAt,
            outcomes: outcomes,
            isComplete: false
        )
        statisticsRecorder.recordQuizSession(summary)
        
        // Список «новых» общий с викториной: забираем только открытые сейчас,
        // чтобы они не показались ещё раз после следующей викторины
        achievementChecker.clearNewAchievements()
        achievementChecker.checkAchievements(
            for: statisticsRecorder.stats,
            dayStreak: statisticsRecorder.dayStreak,
            quizResult: nil
        )
        newAchievements = achievementChecker.newAchievements
        achievementChecker.clearNewAchievements()
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
        
        stoppedTimeRemaining = timerManager.timeRemaining
        questionDeadline = timerManager.deadline
    }
    
    private func stopQuestionTimer() {
        timerManager.stopTimer()
        stoppedTimeRemaining = timerManager.timeRemaining
        questionDeadline = nil
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
    }
}
