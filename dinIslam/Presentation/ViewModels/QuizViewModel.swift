//
//  QuizViewModel.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Observation
import UIKit
import AudioToolbox
import OSLog

@Observable
class QuizViewModel {
    // MARK: - Properties
    private let quizUseCase: QuizUseCaseProtocol
    private let feedbackProvider: QuizFeedbackProviding
    private let statisticsRecorder: QuizStatisticsRecording
    private let achievementChecker: QuizAchievementChecking
    private let localizationProvider: LocalizationProviding
    
    var state: QuizState = .idle
    var questions: [Question] = []
    var currentQuestionIndex: Int = 0
    var correctAnswers: Int = 0
    var selectedAnswerIndex: Int?
    var isAnswerSelected: Bool = false
    var showResult: Bool = false
    var quizResult: QuizResult?
    var errorMessage: String?
    var isLoading: Bool = false
    var sessionKind: QuizSessionKind = .standard
    /// Итог последней завершённой сессии (для экрана результата)
    var lastSessionReport: SessionReport?
    
    // MARK: - Achievement Properties
    var newAchievements: [Achievement] {
        achievementChecker.newAchievements
    }
    
    private var startTime: Date?
    private var questionResults: [String: Bool] = [:] // ID вопроса -> правильный ли ответ
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
    
    /// Переходить к следующему вопросу автоматически; экран выключает это при включённом VoiceOver
    var advancesAutomatically = true
    
    // MARK: - Initialization
    init(
        quizUseCase: QuizUseCaseProtocol,
        feedbackProvider: QuizFeedbackProviding? = nil,
        statisticsRecorder: QuizStatisticsRecording? = nil,
        achievementChecker: QuizAchievementChecking? = nil,
        statsManager: StatsManager? = nil,
        settingsManager: SettingsManager? = nil,
        localizationProvider: LocalizationProviding? = nil
    ) {
        self.quizUseCase = quizUseCase
        
        // Initialize localization provider
        self.localizationProvider = localizationProvider ?? LocalizationManager()
        
        // Initialize statistics recorder - must have either statisticsRecorder or statsManager
        if let statisticsRecorder = statisticsRecorder {
            self.statisticsRecorder = statisticsRecorder
        } else if let statsManager = statsManager {
            self.statisticsRecorder = DefaultQuizStatisticsRecorder(statsManager: statsManager)
        } else {
            // Fallback: create a default StatsManager if nothing provided
            // This should not happen in production, but provides backward compatibility
            let defaultStatsManager = StatsManager()
            self.statisticsRecorder = DefaultQuizStatisticsRecorder(statsManager: defaultStatsManager)
        }
        
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
        
        // Achievement checker requires AchievementManager
        if let achievementChecker = achievementChecker {
            self.achievementChecker = achievementChecker
        } else {
            // Fallback: create default achievement manager for backward compatibility
            self.achievementChecker = DefaultQuizAchievementChecker(
                achievementManager: AchievementManager(notificationManager: NotificationManager())
            )
        }
    }
    
    convenience init(
        quizUseCase: QuizUseCaseProtocol,
        statsManager: StatsManager,
        settingsManager: SettingsManager,
        achievementManager: AchievementManager
    ) {
        // Create default services
        let hapticManager = HapticManager(settingsManager: settingsManager)
        let soundManager = SoundManager(settingsManager: settingsManager)
        let feedbackProvider = DefaultQuizFeedbackProvider(
            hapticManager: hapticManager,
            soundManager: soundManager
        )
        let statisticsRecorder = DefaultQuizStatisticsRecorder(statsManager: statsManager)
        let achievementChecker = DefaultQuizAchievementChecker(
            achievementManager: achievementManager
        )
        
        self.init(
            quizUseCase: quizUseCase,
            feedbackProvider: feedbackProvider,
            statisticsRecorder: statisticsRecorder,
            achievementChecker: achievementChecker
        )
    }
    
    // MARK: - Public Methods
    @MainActor
    func startQuiz(language: String, kind: QuizSessionKind = .standard) async {
        state = .active(.loading)
        isLoading = true
        errorMessage = nil
        sessionKind = kind
        resetSessionTracking()
        
        do {
            let loadedQuestions: [Question]
            if kind == .daily {
                loadedQuestions = try await quizUseCase.startDailyQuiz(language: language)
            } else {
                loadedQuestions = try await quizUseCase.startQuiz(
                    language: language,
                    sessionSize: QuizUseCase.standardSessionSize
                )
            }
            
            // Проверяем, что вопросы действительно получены
            guard !loadedQuestions.isEmpty else {
                // Если банк завершён, это должно быть обработано в StartViewModel,
                // но на случай если проверка не сработала, показываем ошибку
                errorMessage = localizationProvider.localizedString(for: "quiz.bankCompleted")
                state = .idle
                isLoading = false
                return
            }
            
            // Shuffle answers (simple CPU work; safe to do on main actor for small arrays)
            let processedQuestions = loadedQuestions.map { quizUseCase.shuffleAnswers(for: $0) }
            
            questions = processedQuestions
            currentQuestionIndex = 0
            correctAnswers = 0
            selectedAnswerIndex = nil
            isAnswerSelected = false
            showResult = false
            startTime = Date()
            state = .active(.playing)
            isLoading = false
        } catch {
            AppLogger.error("Failed to start quiz", error: error, category: AppLogger.network)
            errorMessage = error.localizedDescription
            state = .error(.networkError)
            isLoading = false
        }
    }
    
    @MainActor
    func selectAnswer(at index: Int) {
        guard !isAnswerSelected else { return }
        
        selectedAnswerIndex = index
        isAnswerSelected = true
        
        // Check if answer is correct
        if let currentQuestion = currentQuestion {
            let isCorrect = index == currentQuestion.correctIndex
            questionResults[currentQuestion.id] = isCorrect
            
            if isCorrect {
                correctAnswers += 1
            }
            
            // Один сигнал на ответ: звук и вибрация «верно/неверно»
            feedbackProvider.answerSelected(isCorrect: isCorrect)
        }
        
        // С VoiceOver переход только по кнопке «Далее»: 1,5 с не хватает, чтобы дослушать результат
        nextQuestionTask?.cancel()
        guard advancesAutomatically else { return }
        
        // Show result briefly before moving to next question
        nextQuestionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            // try? глушит CancellationError, поэтому отмену проверяем явно
            guard !Task.isCancelled else { return }
            self?.nextQuestion()
        }
    }
    
    @MainActor
    func nextQuestion() {
        if isLastQuestion {
            switch state {
            case .active(.playing):
                finishQuiz()
            case .active(.mistakesReview):
                finishMistakesReview()
            default:
                break
            }
        } else {
            nextQuestionTask?.cancel()
            currentQuestionIndex += 1
            selectedAnswerIndex = nil
            isAnswerSelected = false
        }
    }
    
    @MainActor
    func finishQuiz(isComplete: Bool = true) {
        let timeSpent = Date().timeIntervalSince(startTime ?? Date())
        
        // При досрочном завершении учитываем только отвеченные вопросы
        let sessionQuestions = isComplete
            ? questions
            : questions.filter { questionResults[$0.id] != nil }
        
        let result = quizUseCase.calculateResult(
            correctAnswers: correctAnswers,
            totalQuestions: sessionQuestions.count,
            timeSpent: timeSpent
        )
        quizResult = result
        
        if !sessionQuestions.isEmpty {
            let outcomes = sessionQuestions.map { question in
                QuizQuestionOutcome(
                    questionId: question.id,
                    category: question.category,
                    difficulty: question.difficulty,
                    isCorrect: questionResults[question.id] ?? false
                )
            }

            let summary = QuizSessionSummary(
                correctAnswers: correctAnswers,
                totalQuestions: sessionQuestions.count,
                percentage: result.percentage,
                duration: timeSpent,
                completedAt: Date(),
                outcomes: outcomes,
                isComplete: isComplete
            )
            
            statisticsRecorder.recordQuizSession(summary)
            if isComplete && sessionKind == .daily {
                statisticsRecorder.registerDailyGoal()
            }
            
            lastSessionReport = SessionReport(
                kind: sessionKind,
                topicResults: SessionReport.topicResults(for: outcomes),
                mistakeIds: outcomes.filter { !$0.isCorrect }.map(\.questionId),
                dayStreak: statisticsRecorder.dayStreak,
                review: nil
            )
            
            // Достижения за результат сессии (идеальный, быстрый) — только за пройденную до конца викторину
            achievementChecker.checkAchievements(
                for: statisticsRecorder.stats,
                quizResult: isComplete ? result : nil
            )
            
            // Неотвеченные вопросы остаются в пуле и попадутся снова
            quizUseCase.markQuestionsUsed(sessionQuestions.map(\.id))
        }
        
        state = .completed(.finished)
        
        // Provide completion feedback - same as in exam mode
        feedbackProvider.quizCompleted(success: (quizResult?.percentage ?? 0) > 0)
    }
    
    @MainActor
    func forceFinishQuiz() {
        nextQuestionTask?.cancel()
        if state == .active(.mistakesReview) {
            // В повторении сохраняем ответы, которые уже даны
            finishMistakesReview()
        } else {
            // Досрочное завершение: сохраняем ответы, которые уже даны
            finishQuiz(isComplete: false)
        }
    }
    
    private func resetSessionTracking() {
        lastSessionReport = nil
        questionResults.removeAll()
        nextQuestionTask?.cancel()
    }
    
    @MainActor
    func restartQuiz() {
        state = .idle
        questions = []
        currentQuestionIndex = 0
        correctAnswers = 0
        selectedAnswerIndex = nil
        isAnswerSelected = false
        showResult = false
        quizResult = nil
        errorMessage = nil
        lastSessionReport = nil
        sessionKind = .standard
        questionResults.removeAll()
        nextQuestionTask?.cancel()
        nextQuestionTask = nil
    }
    
    // MARK: - Mistakes Review Methods
    @MainActor
    func startMistakesReview(language: String, scope: MistakesReviewScope = .all) async {
        state = .active(.loading)
        isLoading = true
        errorMessage = nil
        sessionKind = .review
        resetSessionTracking()
        
        do {
            // Get all questions to find the wrong ones
            let allQuestions = try await quizUseCase.loadAllQuestions(language: language)
            
            // Filter only wrong questions
            let wrongQuestions = statisticsRecorder.getWrongQuestions(from: allQuestions, scope: scope)
            
            guard !wrongQuestions.isEmpty else {
                errorMessage = localizationProvider.localizedString(
                    for: scope == .due ? "review.nothingDue" : "mistakes.noWrongQuestions"
                )
                state = .idle
                isLoading = false
                return
            }
            
            // Shuffle wrong questions
            questions = wrongQuestions.shuffled().map { quizUseCase.shuffleAnswers(for: $0) }
            currentQuestionIndex = 0
            correctAnswers = 0
            selectedAnswerIndex = nil
            isAnswerSelected = false
            showResult = false
            startTime = Date()
            state = .active(.mistakesReview)
        } catch {
            AppLogger.error("Failed to start mistakes review", error: error, category: AppLogger.data)
            errorMessage = error.localizedDescription
            state = .idle
        }
        
        isLoading = false
    }
    
    @MainActor
    func finishMistakesReview() {
        let timeSpent = Date().timeIntervalSince(startTime ?? Date())
        // При досрочном завершении процент считается от отвеченных вопросов, как в обычной викторине
        quizResult = quizUseCase.calculateResult(
            correctAnswers: correctAnswers,
            totalQuestions: questionResults.count,
            timeSpent: timeSpent
        )

        // Продвигаем вопросы по расписанию повторения; выученные уходят из списка ошибок
        let reviewSummary = statisticsRecorder.recordReviewAnswers(questionResults)
        let outcomes = questions.compactMap { question -> QuizQuestionOutcome? in
            guard let isCorrect = questionResults[question.id] else { return nil }
            return QuizQuestionOutcome(
                questionId: question.id,
                category: question.category,
                difficulty: question.difficulty,
                isCorrect: isCorrect
            )
        }
        lastSessionReport = SessionReport(
            kind: .review,
            topicResults: SessionReport.topicResults(for: outcomes),
            mistakeIds: outcomes.filter { !$0.isCorrect }.map(\.questionId),
            dayStreak: statisticsRecorder.dayStreak,
            review: reviewSummary
        )
        
        state = .completed(.mistakesFinished)
        
        // Provide completion feedback - same as in exam mode
        feedbackProvider.quizCompleted(success: true)
    }
    
    // MARK: - Achievement Methods
    func clearNewAchievements() {
        achievementChecker.clearNewAchievements()
    }

    deinit {
        nextQuestionTask?.cancel()
    }
}

// MARK: - Haptic Feedback Manager
class HapticManager {
    private var settingsManager: SettingsManager?
    
    init(settingsManager: SettingsManager? = nil) {
        self.settingsManager = settingsManager
    }
    
    func setSettingsManager(_ settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    private func isHapticEnabled() -> Bool {
        return settingsManager?.settings.hapticEnabled ?? true
    }
    
    func selectionChanged() {
        guard isHapticEnabled() else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func success() {
        guard isHapticEnabled() else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    func error() {
        guard isHapticEnabled() else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
}

// MARK: - Sound Manager
class SoundManager {
    private var settingsManager: SettingsManager?
    
    init(settingsManager: SettingsManager? = nil) {
        self.settingsManager = settingsManager
    }
    
    func setSettingsManager(_ settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    private func isSoundEnabled() -> Bool {
        return settingsManager?.settings.soundEnabled ?? true
    }
    
    func playSuccessSound() {
        guard isSoundEnabled() else { return }
        playSystemSound(1103) // Success sound
    }
    
    func playErrorSound() {
        guard isSoundEnabled() else { return }
        playSystemSound(1104) // Error sound
    }
    
    func playSelectionSound() {
        guard isSoundEnabled() else { return }
        playSystemSound(1105) // Selection sound
    }
    
    private func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
}
