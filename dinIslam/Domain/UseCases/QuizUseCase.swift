//
//  QuizUseCase.swift
//  dinIslam
//
//  Created by Saydulayev on 20.10.25.
//

import Foundation

protocol QuizUseCaseProtocol {
    func startQuiz(language: String) async throws -> [Question]
    func shuffleAnswers(for question: Question) -> Question
    func calculateResult(correctAnswers: Int, totalQuestions: Int, timeSpent: TimeInterval) -> QuizResult
}

class QuizUseCase: QuizUseCaseProtocol {
    private let questionsRepository: QuestionsRepositoryProtocol
    private let questionPoolVersion = 1
    
    init(questionsRepository: QuestionsRepositoryProtocol) {
        self.questionsRepository = questionsRepository
    }
    
    func startQuiz(language: String) async throws -> [Question] {
        let allQuestions = try await questionsRepository.loadQuestions(language: language)
        let progress = QuestionPoolProgress(version: questionPoolVersion)
        let used = progress.usedIds
        var available = allQuestions.filter { !used.contains($0.id) }
        
        let sessionCount = 20
        if available.count < sessionCount {
            progress.reset(for: questionPoolVersion)
            available = allQuestions
        }
        
        let selected = Array(available.shuffled().prefix(sessionCount))
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
            difficulty: question.difficulty,
            language: question.language
        )
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
}
