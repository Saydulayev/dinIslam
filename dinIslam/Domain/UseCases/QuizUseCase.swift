//
//  QuizUseCase.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

protocol QuizUseCaseProtocol {
    func startQuiz(language: String) async throws -> [Question]
    func loadAllQuestions(language: String) async throws -> [Question]
    func shuffleAnswers(for question: Question) -> Question
    func calculateResult(correctAnswers: Int, totalQuestions: Int, timeSpent: TimeInterval) -> QuizResult
}

class QuizUseCase: QuizUseCaseProtocol {
    private let questionsRepository: QuestionsRepositoryProtocol
    private let adaptiveEngine: AdaptiveLearningEngine
    private let profileManager: ProfileManager
    private let questionPoolVersion = 1
    
    init(
        questionsRepository: QuestionsRepositoryProtocol,
        adaptiveEngine: AdaptiveLearningEngine,
        profileManager: ProfileManager
    ) {
        self.questionsRepository = questionsRepository
        self.adaptiveEngine = adaptiveEngine
        self.profileManager = profileManager
    }
    
    func startQuiz(language: String) async throws -> [Question] {
        let allQuestions = try await questionsRepository.loadQuestions(language: language)
        let progress = QuestionPoolProgress(version: questionPoolVersion)
        let used = progress.usedIds
        let sessionCount = min(20, allQuestions.count) // Адаптивный размер сессии
        var selected = adaptiveEngine.selectQuestions(
            from: allQuestions,
            progress: profileManager.progress,
            usedQuestionIds: used,
            sessionCount: sessionCount
        )
        
        if selected.count < sessionCount {
            let remainingNewQuestions = allQuestions.filter { question in
                !used.contains(question.id) && !selected.contains(where: { $0.id == question.id })
            }
            if !remainingNewQuestions.isEmpty {
                let remainingNeeded = sessionCount - selected.count
                selected.append(contentsOf: Array(remainingNewQuestions.shuffled().prefix(remainingNeeded)))
            }
        }
        
        if selected.count < sessionCount {
            let fallback = allQuestions.filter { question in
                !selected.contains(where: { $0.id == question.id })
            }
            let remainingNeeded = sessionCount - selected.count
            selected.append(contentsOf: Array(fallback.shuffled().prefix(remainingNeeded)))
        }
        
        progress.markUsed(selected.map { $0.id })
        return selected
    }
    
    func shuffleAnswers(for question: Question) -> Question {
        let shuffledAnswers = question.answers.shuffled()
        let correctAnswer = question.answers[question.correctIndex]
        
        // Find the new index of the correct answer
        guard let newCorrectIndex = shuffledAnswers.firstIndex(where: { $0.id == correctAnswer.id }) else {
            return question
        }
        
        return Question(
            id: question.id,
            text: question.text,
            answers: shuffledAnswers,
            correctIndex: newCorrectIndex,
            category: question.category,
            difficulty: question.difficulty
        )
    }
    
    func loadAllQuestions(language: String) async throws -> [Question] {
        return try await questionsRepository.loadQuestions(language: language)
    }
    
    func calculateResult(correctAnswers: Int, totalQuestions: Int, timeSpent: TimeInterval) -> QuizResult {
        let percentage = totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) * 100 : 0
        return QuizResult(
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
            percentage: percentage,
            timeSpent: timeSpent
        )
    }
    
    func getProgressStats(language: String) async throws -> (total: Int, used: Int, remaining: Int) {
        let allQuestions = try await questionsRepository.loadQuestions(language: language)
        let progress = QuestionPoolProgress(version: questionPoolVersion)
        let usedCount = progress.usedIds.count
        let remainingCount = allQuestions.count - usedCount
        
        return (
            total: allQuestions.count,
            used: usedCount,
            remaining: remainingCount
        )
    }
}
