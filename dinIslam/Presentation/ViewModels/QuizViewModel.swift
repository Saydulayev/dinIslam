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

@Observable
class QuizViewModel {
    // MARK: - Properties
    private let quizUseCase: QuizUseCaseProtocol
    private let hapticManager: HapticManager
    private let soundManager: SoundManager
    private let statsManager: StatsManager
    private let achievementManager: AchievementManager
    
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
    
    // MARK: - Achievement Properties
    var newAchievements: [Achievement] {
        achievementManager.newAchievements
    }
    
    private var startTime: Date?
    private var questionResults: [String: Bool] = [:] // ID вопроса -> правильный ли ответ
    
    // Мемоизация для избежания повторных вычислений
    private var memoizedProgress: Double?
    private var memoizedCurrentQuestion: Question?
    
    // MARK: - Computed Properties
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        
        // Мемоизация для избежания повторных обращений к массиву
        if let memoized = memoizedCurrentQuestion, 
           memoized.id == questions[currentQuestionIndex].id {
            return memoized
        }
        
        let question = questions[currentQuestionIndex]
        memoizedCurrentQuestion = question
        return question
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        
        // Мемоизация прогресса
        if let memoized = memoizedProgress {
            return memoized
        }
        
        let progressValue = Double(currentQuestionIndex) / Double(questions.count)
        memoizedProgress = progressValue
        return progressValue
    }
    
    var isLastQuestion: Bool {
        return currentQuestionIndex == questions.count - 1
    }
    
    // MARK: - Initialization
    init(quizUseCase: QuizUseCaseProtocol, statsManager: StatsManager, settingsManager: SettingsManager) {
        self.quizUseCase = quizUseCase
        self.statsManager = statsManager
        self.hapticManager = HapticManager(settingsManager: settingsManager)
        self.soundManager = SoundManager(settingsManager: settingsManager)
        self.achievementManager = AchievementManager()
    }
    
    // MARK: - Public Methods
    @MainActor
    func startQuiz(language: String) async {
        state = .active(.loading)
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedQuestions = try await quizUseCase.startQuiz(language: language)
            
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
        
        // Provide haptic and sound feedback
        hapticManager.selectionChanged()
        soundManager.playSelectionSound()
        
        // Check if answer is correct
        if let currentQuestion = currentQuestion {
            let isCorrect = index == currentQuestion.correctIndex
            questionResults[currentQuestion.id] = isCorrect
            
            print("DEBUG: Question \(currentQuestion.id) answered \(isCorrect ? "correctly" : "incorrectly")")
            
            if isCorrect {
                correctAnswers += 1
                hapticManager.success()
                soundManager.playSuccessSound()
            } else {
                hapticManager.error()
                soundManager.playErrorSound()
            }
        }
        
        // Show result briefly before moving to next question
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            nextQuestion()
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
            currentQuestionIndex += 1
            selectedAnswerIndex = nil
            isAnswerSelected = false
            
            // Сброс мемоизации при переходе к следующему вопросу
            memoizedProgress = nil
            memoizedCurrentQuestion = nil
        }
    }
    
    @MainActor
    func finishQuiz(isComplete: Bool = true) {
        let timeSpent = Date().timeIntervalSince(startTime ?? Date())
        quizResult = quizUseCase.calculateResult(
            correctAnswers: correctAnswers,
            totalQuestions: questions.count,
            timeSpent: timeSpent
        )
        
        // Обновляем статистику только если викторина завершена полностью
        if isComplete {
            let wrongQuestionIds = questionResults.compactMap { (questionId, isCorrect) in
                return isCorrect ? nil : questionId
            }
            
            statsManager.updateStats(
                correctCount: correctAnswers,
                totalCount: questions.count,
                wrongQuestionIds: wrongQuestionIds,
                percentage: quizResult?.percentage ?? 0
            )
            
            // Check for new achievements
            achievementManager.checkAchievements(for: statsManager.stats, quizResult: quizResult)
        }
        
        state = .completed(.finished)
        
        // Provide completion feedback - same as in exam mode
        hapticManager.success()
        soundManager.playSuccessSound()
    }
    
    @MainActor
    func forceFinishQuiz() {
        // Force finish quiz with current progress - don't update stats for incomplete quiz
        finishQuiz(isComplete: false)
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
        questionResults.removeAll()
        
        // Сброс мемоизации при перезапуске
        memoizedProgress = nil
        memoizedCurrentQuestion = nil
    }
    
    // MARK: - Mistakes Review Methods
    @MainActor
    func startMistakesReview() async {
        print("DEBUG: QuizViewModel.startMistakesReview() called")
        state = .active(.loading)
        isLoading = true
        errorMessage = nil
        
        do {
            // Get all questions to find the wrong ones
            let languageCode = LocalizationManager.shared.currentLanguage
            print("DEBUG: Loading questions for language: \(languageCode)")
            let allQuestions = try await quizUseCase.loadAllQuestions(language: languageCode)
            print("DEBUG: Loaded \(allQuestions.count) total questions")
            
            // Filter only wrong questions
            let wrongQuestions = statsManager.getWrongQuestions(from: allQuestions)
            print("DEBUG: Found \(wrongQuestions.count) wrong questions")
            
            guard !wrongQuestions.isEmpty else {
                print("DEBUG: No wrong questions found")
                errorMessage = LocalizationManager.shared.localizedString(for: "mistakes.noWrongQuestions")
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
            print("DEBUG: Set state to mistakesReview with \(questions.count) questions")
        } catch {
            print("DEBUG: Error loading questions: \(error)")
            errorMessage = error.localizedDescription
            state = .idle
        }
        
        isLoading = false
        print("DEBUG: QuizViewModel.startMistakesReview() completed. State: \(state)")
    }
    
    @MainActor
    func finishMistakesReview() {
        let timeSpent = Date().timeIntervalSince(startTime ?? Date())
        quizResult = quizUseCase.calculateResult(
            correctAnswers: correctAnswers,
            totalQuestions: questions.count,
            timeSpent: timeSpent
        )
        
        // Update stats - remove correctly answered questions from wrong list
        let correctlyAnsweredIds = questionResults.compactMap { (questionId, isCorrect) in
            return isCorrect ? questionId : nil
        }
        
        print("DEBUG: Correctly answered question IDs: \(correctlyAnsweredIds)")
        print("DEBUG: Total question results: \(questionResults)")
        
        // Remove correctly answered questions from wrong questions list
        for questionId in correctlyAnsweredIds {
            print("DEBUG: Removing question \(questionId) from wrong questions list")
            statsManager.removeWrongQuestion(questionId)
        }
        
        print("DEBUG: Wrong questions after removal: \(statsManager.stats.wrongQuestionIds.count)")
        
        state = .completed(.mistakesFinished)
        
        // Provide completion feedback - same as in exam mode
        hapticManager.success()
        soundManager.playSuccessSound()
    }
    
    // MARK: - Achievement Methods
    func clearNewAchievements() {
        achievementManager.clearNewAchievements()
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
