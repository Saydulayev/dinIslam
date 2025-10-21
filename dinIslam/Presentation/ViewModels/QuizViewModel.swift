//
//  QuizViewModel.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation
import Observation
import UIKit

@Observable
class QuizViewModel {
    // MARK: - Properties
    private let quizUseCase: QuizUseCaseProtocol
    private let hapticManager: HapticManager
    private let statsManager: StatsManager
    
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
    
    private var startTime: Date?
    private var questionResults: [String: Bool] = [:] // ID вопроса -> правильный ли ответ
    
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
    
    // MARK: - Initialization
    init(quizUseCase: QuizUseCaseProtocol, statsManager: StatsManager, settingsManager: SettingsManager) {
        self.quizUseCase = quizUseCase
        self.statsManager = statsManager
        self.hapticManager = HapticManager(settingsManager: settingsManager)
    }
    
    // MARK: - Public Methods
    @MainActor
    func startQuiz(language: String) async {
        state = .loading
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedQuestions = try await quizUseCase.startQuiz(language: language)
            questions = loadedQuestions.map { quizUseCase.shuffleAnswers(for: $0) }
            currentQuestionIndex = 0
            correctAnswers = 0
            selectedAnswerIndex = nil
            isAnswerSelected = false
            showResult = false
            startTime = Date()
            state = .playing
        } catch {
            errorMessage = error.localizedDescription
            state = .idle
        }
        
        isLoading = false
    }
    
    @MainActor
    func selectAnswer(at index: Int) {
        guard !isAnswerSelected else { return }
        
        selectedAnswerIndex = index
        isAnswerSelected = true
        
        // Provide haptic feedback
        hapticManager.selectionChanged()
        
        // Check if answer is correct
        if let currentQuestion = currentQuestion {
            let isCorrect = index == currentQuestion.correctIndex
            questionResults[currentQuestion.id] = isCorrect
            
            print("DEBUG: Question \(currentQuestion.id) answered \(isCorrect ? "correctly" : "incorrectly")")
            
            if isCorrect {
                correctAnswers += 1
                hapticManager.success()
            } else {
                hapticManager.error()
            }
        }
        
        // Show result briefly before moving to next question
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.nextQuestion()
        }
    }
    
    @MainActor
    func nextQuestion() {
        if isLastQuestion {
            if state == .playing {
                finishQuiz()
            } else if state == .mistakesReview {
                finishMistakesReview()
            }
        } else {
            currentQuestionIndex += 1
            selectedAnswerIndex = nil
            isAnswerSelected = false
        }
    }
    
    @MainActor
    func finishQuiz() {
        let timeSpent = Date().timeIntervalSince(startTime ?? Date())
        quizResult = quizUseCase.calculateResult(
            correctAnswers: correctAnswers,
            totalQuestions: questions.count,
            timeSpent: timeSpent
        )
        
        // Обновляем статистику
        let wrongQuestionIds = questionResults.compactMap { (questionId, isCorrect) in
            return isCorrect ? nil : questionId
        }
        
        statsManager.updateStats(
            correctCount: correctAnswers,
            totalCount: questions.count,
            wrongQuestionIds: wrongQuestionIds
        )
        
        state = .finished
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
    }
    
    // MARK: - Mistakes Review Methods
    @MainActor
    func startMistakesReview() async {
        print("DEBUG: QuizViewModel.startMistakesReview() called")
        state = .loading
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
            state = .mistakesReview
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
        
        state = .mistakesFinished
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
