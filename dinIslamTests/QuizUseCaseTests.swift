//
//  QuizUseCaseTests.swift
//  dinIslamTests
//
//  Created on 27.01.25.
//

import XCTest
@testable import dinIslam

final class QuizUseCaseTests: XCTestCase {
    
    var sut: QuizUseCase!
    var mockRepository: MockQuestionsRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockQuestionsRepository()
        sut = QuizUseCase(questionsRepository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - startQuiz Tests
    
    func testStartQuiz_Returns20Questions() async throws {
        // Given
        mockRepository.mockQuestions = createMockQuestions(count: 100)
        
        // When
        let questions = try await sut.startQuiz(language: "ru")
        
        // Then
        XCTAssertEqual(questions.count, 20, "Should return exactly 20 questions")
    }
    
    func testStartQuiz_ReturnsAllQuestionsWhenLessThan20() async throws {
        // Given
        mockRepository.mockQuestions = createMockQuestions(count: 15)
        
        // When
        let questions = try await sut.startQuiz(language: "ru")
        
        // Then
        XCTAssertEqual(questions.count, 15, "Should return all available questions when less than 20")
    }
    
    func testStartQuiz_ReturnsUniqueQuestions() async throws {
        // Given
        mockRepository.mockQuestions = createMockQuestions(count: 50)
        
        // When
        let questions = try await sut.startQuiz(language: "ru")
        
        // Then
        let questionIds = await MainActor.run {
            Set(questions.map { $0.id })
        }
        XCTAssertEqual(questionIds.count, questions.count, "All questions should be unique")
    }
    
    func testStartQuiz_ThrowsErrorWhenRepositoryFails() async {
        // Given
        mockRepository.shouldFail = true
        
        // When/Then
        do {
            _ = try await sut.startQuiz(language: "ru")
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error, "Should propagate repository error")
        }
    }
    
    // MARK: - shuffleAnswers Tests
    
    func testShuffleAnswers_ShufflesAnswerOrder() {
        // Given
        let question = createMockQuestion(id: "q1")
        let originalAnswers = question.answers
        let originalCorrectIndex = question.correctIndex
        let originalCorrectAnswer = question.answers[originalCorrectIndex]
        
        // When
        let shuffledQuestion = sut.shuffleAnswers(for: question)
        
        // Then
        XCTAssertNotEqual(shuffledQuestion.answers, originalAnswers, "Answers should be shuffled")
        XCTAssertEqual(shuffledQuestion.answers.count, originalAnswers.count, "Should have same number of answers")
        
        // Check that correct answer is still in the list
        let correctAnswerExists = shuffledQuestion.answers.contains { $0.id == originalCorrectAnswer.id }
        XCTAssertTrue(correctAnswerExists, "Correct answer should still be in the list")
        
        // Check that correct index points to the same answer
        let newCorrectAnswer = shuffledQuestion.answers[shuffledQuestion.correctIndex]
        XCTAssertEqual(newCorrectAnswer.id, originalCorrectAnswer.id, "Correct answer ID should match")
    }
    
    func testShuffleAnswers_PreservesQuestionData() {
        // Given
        let question = createMockQuestion(id: "q1")
        
        // When
        let shuffledQuestion = sut.shuffleAnswers(for: question)
        
        // Then
        XCTAssertEqual(shuffledQuestion.id, question.id, "Question ID should be preserved")
        XCTAssertEqual(shuffledQuestion.text, question.text, "Question text should be preserved")
        XCTAssertEqual(shuffledQuestion.category, question.category, "Category should be preserved")
        XCTAssertEqual(shuffledQuestion.difficulty, question.difficulty, "Difficulty should be preserved")
    }
    
    // MARK: - calculateResult Tests
    
    func testCalculateResult_CalculatesCorrectPercentage() {
        // Given
        let correctAnswers = 15
        let totalQuestions = 20
        let timeSpent: TimeInterval = 120.0
        
        // When
        let result = sut.calculateResult(
            correctAnswers: correctAnswers,
            totalQuestions: totalQuestions,
            timeSpent: timeSpent
        )
        
        // Then
        XCTAssertEqual(result.totalQuestions, totalQuestions)
        XCTAssertEqual(result.correctAnswers, correctAnswers)
        XCTAssertEqual(result.percentage, 75.0, accuracy: 0.01)
        XCTAssertEqual(result.timeSpent, timeSpent)
    }
    
    func testCalculateResult_HandlesZeroTotalQuestions() {
        // Given
        let correctAnswers = 0
        let totalQuestions = 0
        let timeSpent: TimeInterval = 0.0
        
        // When
        let result = sut.calculateResult(
            correctAnswers: correctAnswers,
            totalQuestions: totalQuestions,
            timeSpent: timeSpent
        )
        
        // Then
        XCTAssertEqual(result.percentage, 0.0, "Percentage should be 0 when total is 0")
    }
    
    func testCalculateResult_Calculates100Percent() {
        // Given
        let correctAnswers = 20
        let totalQuestions = 20
        let timeSpent: TimeInterval = 180.0
        
        // When
        let result = sut.calculateResult(
            correctAnswers: correctAnswers,
            totalQuestions: totalQuestions,
            timeSpent: timeSpent
        )
        
        // Then
        XCTAssertEqual(result.percentage, 100.0, accuracy: 0.01)
    }
    
    func testCalculateResult_HandlesPartialScore() {
        // Given
        let correctAnswers = 7
        let totalQuestions = 10
        let timeSpent: TimeInterval = 90.0
        
        // When
        let result = sut.calculateResult(
            correctAnswers: correctAnswers,
            totalQuestions: totalQuestions,
            timeSpent: timeSpent
        )
        
        // Then
        XCTAssertEqual(result.percentage, 70.0, accuracy: 0.01)
    }
    
    // MARK: - loadAllQuestions Tests
    
    func testLoadAllQuestions_ReturnsAllQuestionsFromRepository() async throws {
        // Given
        let expectedQuestions = createMockQuestions(count: 50)
        mockRepository.mockQuestions = expectedQuestions
        
        // When
        let questions = try await sut.loadAllQuestions(language: "ru")
        
        // Then
        XCTAssertEqual(questions.count, expectedQuestions.count)
        let questionIds = await MainActor.run {
            questions.map { $0.id }
        }
        let expectedIds = await MainActor.run {
            expectedQuestions.map { $0.id }
        }
        XCTAssertEqual(questionIds, expectedIds)
    }
    
    // MARK: - Helper Methods
    
    private func createMockQuestion(id: String) -> Question {
        Question(
            id: id,
            text: "Test question \(id)",
            answers: [
                Answer(id: "a1", text: "Answer 1"),
                Answer(id: "a2", text: "Answer 2"),
                Answer(id: "a3", text: "Answer 3"),
                Answer(id: "a4", text: "Answer 4")
            ],
            correctIndex: 0,
            category: "Test",
            difficulty: .medium
        )
    }
    
    private func createMockQuestions(count: Int) -> [Question] {
        (1...count).map { index in
            createMockQuestion(id: "q\(index)")
        }
    }
}

// MARK: - Mock Repository

class MockQuestionsRepository: QuestionsRepositoryProtocol {
    var mockQuestions: [Question] = []
    var shouldFail = false
    var loadQuestionsCallCount = 0
    
    func loadQuestions(language: String) async throws -> [Question] {
        loadQuestionsCallCount += 1
        
        if shouldFail {
            throw QuestionsError.fileNotFound
        }
        
        return mockQuestions
    }
}

