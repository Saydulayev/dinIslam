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
    private let hapticManager = HapticManager()
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
    init(quizUseCase: QuizUseCaseProtocol, statsManager: StatsManager) {
        self.quizUseCase = quizUseCase
        self.statsManager = statsManager
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
            finishQuiz()
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
}

// MARK: - Haptic Feedback Manager
class HapticManager {
    func selectionChanged() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
}
