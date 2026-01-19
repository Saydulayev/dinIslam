//
//  QuestionValidator.swift
//  dinIslam
//
//  Created by Assistant on 19.01.26.
//

import Foundation
import OSLog

// MARK: - Validation Error Types
enum ValidationError: Error, LocalizedError {
    case invalidCorrectIndex(questionId: String, index: Int, answersCount: Int)
    case emptyText(questionId: String)
    case insufficientAnswers(questionId: String, count: Int)
    case duplicateQuestionId(questionId: String)
    case emptyAnswerText(questionId: String, answerIndex: Int)
    case negativeCorrectIndex(questionId: String, index: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidCorrectIndex(let questionId, let index, let answersCount):
            return "Question '\(questionId)': correctIndex \(index) is out of bounds (answers count: \(answersCount))"
        case .emptyText(let questionId):
            return "Question '\(questionId)': text is empty"
        case .insufficientAnswers(let questionId, let count):
            return "Question '\(questionId)': insufficient answers (got \(count), need at least 2)"
        case .duplicateQuestionId(let questionId):
            return "Duplicate question ID found: '\(questionId)'"
        case .emptyAnswerText(let questionId, let answerIndex):
            return "Question '\(questionId)': answer at index \(answerIndex) has empty text"
        case .negativeCorrectIndex(let questionId, let index):
            return "Question '\(questionId)': correctIndex is negative (\(index))"
        }
    }
}

// MARK: - Question Validating Protocol
protocol QuestionValidating {
    func validate(_ questions: [Question]) throws
    func isValid(_ question: Question) -> Bool
}

// MARK: - Question Validator Implementation
class QuestionValidator: QuestionValidating {
    
    /// Validates an array of questions
    /// - Parameter questions: Array of questions to validate
    /// - Throws: ValidationError if validation fails
    func validate(_ questions: [Question]) throws {
        // Track question IDs to detect duplicates
        var seenIds = Set<String>()
        
        for (arrayIndex, question) in questions.enumerated() {
            // 1. Check for duplicate IDs
            if seenIds.contains(question.id) {
                AppLogger.error(
                    "Validation failed: Duplicate question ID '\(question.id)' at array index \(arrayIndex)",
                    category: AppLogger.data
                )
                throw ValidationError.duplicateQuestionId(questionId: question.id)
            }
            seenIds.insert(question.id)
            
            // 2. Validate individual question
            try validateSingleQuestion(question)
        }
        
        AppLogger.info("Successfully validated \(questions.count) questions", category: AppLogger.data)
    }
    
    /// Checks if a single question is valid without throwing
    /// - Parameter question: Question to check
    /// - Returns: true if valid, false otherwise
    func isValid(_ question: Question) -> Bool {
        do {
            try validateSingleQuestion(question)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func validateSingleQuestion(_ question: Question) throws {
        // 1. Validate correctIndex is non-negative
        guard question.correctIndex >= 0 else {
            AppLogger.error(
                "Validation failed: Question '\(question.id)' has negative correctIndex: \(question.correctIndex)",
                category: AppLogger.data
            )
            throw ValidationError.negativeCorrectIndex(
                questionId: question.id,
                index: question.correctIndex
            )
        }
        
        // 2. Validate correctIndex is within bounds
        guard question.correctIndex < question.answers.count else {
            AppLogger.error(
                "Validation failed: Question '\(question.id)' correctIndex \(question.correctIndex) >= answers.count \(question.answers.count)",
                category: AppLogger.data
            )
            throw ValidationError.invalidCorrectIndex(
                questionId: question.id,
                index: question.correctIndex,
                answersCount: question.answers.count
            )
        }
        
        // 3. Validate question text is not empty
        guard !question.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            AppLogger.error(
                "Validation failed: Question '\(question.id)' has empty text",
                category: AppLogger.data
            )
            throw ValidationError.emptyText(questionId: question.id)
        }
        
        // 4. Validate minimum number of answers (at least 2)
        guard question.answers.count >= 2 else {
            AppLogger.error(
                "Validation failed: Question '\(question.id)' has only \(question.answers.count) answer(s)",
                category: AppLogger.data
            )
            throw ValidationError.insufficientAnswers(
                questionId: question.id,
                count: question.answers.count
            )
        }
        
        // 5. Validate all answers have non-empty text
        for (index, answer) in question.answers.enumerated() {
            guard !answer.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                AppLogger.error(
                    "Validation failed: Question '\(question.id)' has empty answer text at index \(index)",
                    category: AppLogger.data
                )
                throw ValidationError.emptyAnswerText(
                    questionId: question.id,
                    answerIndex: index
                )
            }
        }
    }
}
