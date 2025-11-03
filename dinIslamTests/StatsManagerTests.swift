//
//  StatsManagerTests.swift
//  dinIslamTests
//
//  Created on 27.01.25.
//

import XCTest
@testable import dinIslam

@MainActor
final class StatsManagerTests: XCTestCase {
    
    var sut: StatsManager!
    
    override func setUp() {
        super.setUp()
        // Создаем новый StatsManager для каждого теста
        sut = StatsManager()
        // Очищаем статистику перед каждым тестом
        sut.resetStats()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - updateStats Tests
    
    func testUpdateStats_UpdatesCorrectAnswers() {
        // Given
        let correctCount = 15
        let totalCount = 20
        let wrongIds: [String] = []
        let percentage = 75.0
        
        // When
        sut.updateStats(
            correctCount: correctCount,
            totalCount: totalCount,
            wrongQuestionIds: wrongIds,
            percentage: percentage
        )
        
        // Then
        XCTAssertEqual(sut.stats.correctAnswers, correctCount)
        XCTAssertEqual(sut.stats.totalQuestionsStudied, totalCount)
        XCTAssertEqual(sut.stats.lastQuizPercentage, percentage)
    }
    
    func testUpdateStats_TracksWrongQuestions() {
        // Given
        let wrongIds = ["q1", "q2", "q3"]
        
        // When
        sut.updateStats(
            correctCount: 17,
            totalCount: 20,
            wrongQuestionIds: wrongIds,
            percentage: 85.0
        )
        
        // Then
        XCTAssertEqual(sut.stats.wrongQuestionIds.count, 3)
        XCTAssertTrue(sut.stats.wrongQuestionIds.contains("q1"))
        XCTAssertTrue(sut.stats.wrongQuestionIds.contains("q2"))
        XCTAssertTrue(sut.stats.wrongQuestionIds.contains("q3"))
    }
    
    func testUpdateStats_AccumulatesStats() {
        // Given
        sut.updateStats(
            correctCount: 10,
            totalCount: 20,
            wrongQuestionIds: ["q1"],
            percentage: 50.0
        )
        
        // When
        sut.updateStats(
            correctCount: 15,
            totalCount: 20,
            wrongQuestionIds: ["q2"],
            percentage: 75.0
        )
        
        // Then
        XCTAssertEqual(sut.stats.correctAnswers, 25) // 10 + 15
        XCTAssertEqual(sut.stats.totalQuestionsStudied, 40) // 20 + 20
        XCTAssertEqual(sut.stats.wrongQuestionIds.count, 2) // q1 and q2
    }
    
    // MARK: - removeWrongQuestion Tests
    
    func testRemoveWrongQuestion_RemovesQuestionFromWrongList() {
        // Given
        sut.updateStats(
            correctCount: 17,
            totalCount: 20,
            wrongQuestionIds: ["q1", "q2", "q3"],
            percentage: 85.0
        )
        
        XCTAssertEqual(sut.stats.wrongQuestionIds.count, 3)
        
        // When
        sut.removeWrongQuestion("q2")
        
        // Then
        XCTAssertEqual(sut.stats.wrongQuestionIds.count, 2)
        XCTAssertFalse(sut.stats.wrongQuestionIds.contains("q2"))
        XCTAssertTrue(sut.stats.wrongQuestionIds.contains("q1"))
        XCTAssertTrue(sut.stats.wrongQuestionIds.contains("q3"))
    }
    
    func testRemoveWrongQuestion_DoesNothingWhenQuestionNotInList() {
        // Given
        sut.updateStats(
            correctCount: 17,
            totalCount: 20,
            wrongQuestionIds: ["q1", "q2"],
            percentage: 85.0
        )
        
        let initialCount = sut.stats.wrongQuestionIds.count
        
        // When
        sut.removeWrongQuestion("q999")
        
        // Then
        XCTAssertEqual(sut.stats.wrongQuestionIds.count, initialCount)
    }
    
    // MARK: - clearWrongQuestions Tests
    
    func testClearWrongQuestions_RemovesAllWrongQuestions() {
        // Given
        sut.updateStats(
            correctCount: 15,
            totalCount: 20,
            wrongQuestionIds: ["q1", "q2", "q3", "q4", "q5"],
            percentage: 75.0
        )
        
        XCTAssertEqual(sut.stats.wrongQuestionIds.count, 5)
        
        // When
        sut.clearWrongQuestions()
        
        // Then
        XCTAssertEqual(sut.stats.wrongQuestionIds.count, 0)
    }
    
    // MARK: - getWrongQuestions Tests
    
    func testGetWrongQuestions_ReturnsCorrectQuestions() {
        // Given
        let allQuestions = [
            Question(id: "q1", text: "Q1", answers: [], correctIndex: 0, category: "Test", difficulty: .medium),
            Question(id: "q2", text: "Q2", answers: [], correctIndex: 0, category: "Test", difficulty: .medium),
            Question(id: "q3", text: "Q3", answers: [], correctIndex: 0, category: "Test", difficulty: .medium),
            Question(id: "q4", text: "Q4", answers: [], correctIndex: 0, category: "Test", difficulty: .medium)
        ]
        
        sut.updateStats(
            correctCount: 2,
            totalCount: 4,
            wrongQuestionIds: ["q1", "q3"],
            percentage: 50.0
        )
        
        // When
        let wrongQuestions = sut.getWrongQuestions(from: allQuestions)
        
        // Then
        XCTAssertEqual(wrongQuestions.count, 2)
        let wrongQuestionIds = wrongQuestions.map { question in question.id }
        XCTAssertEqual(wrongQuestionIds, ["q1", "q3"])
    }
    
    func testGetWrongQuestions_ReturnsEmptyWhenNoWrongQuestions() {
        // Given
        let allQuestions = [
            Question(id: "q1", text: "Q1", answers: [], correctIndex: 0, category: "Test", difficulty: .medium)
        ]
        
        sut.updateStats(
            correctCount: 1,
            totalCount: 1,
            wrongQuestionIds: [],
            percentage: 100.0
        )
        
        // When
        let wrongQuestions = sut.getWrongQuestions(from: allQuestions)
        
        // Then
        XCTAssertEqual(wrongQuestions.count, 0)
    }
    
    // MARK: - resetStats Tests
    
    func testResetStats_ClearsAllStats() {
        // Given
        sut.updateStats(
            correctCount: 15,
            totalCount: 20,
            wrongQuestionIds: ["q1", "q2"],
            percentage: 75.0
        )
        
        XCTAssertEqual(sut.stats.correctAnswers, 15)
        XCTAssertEqual(sut.stats.totalQuestionsStudied, 20)
        XCTAssertEqual(sut.stats.wrongQuestionIds.count, 2)
        
        // When
        sut.resetStats()
        
        // Then
        XCTAssertEqual(sut.stats.correctAnswers, 0)
        XCTAssertEqual(sut.stats.totalQuestionsStudied, 0)
        XCTAssertEqual(sut.stats.wrongQuestionIds.count, 0)
        XCTAssertEqual(sut.stats.lastQuizPercentage, 0)
    }
    
    // MARK: - Accuracy Tests
    
    func testAccuracyPercentage_CalculatesCorrectly() {
        // Given
        sut.updateStats(
            correctCount: 15,
            totalCount: 20,
            wrongQuestionIds: [],
            percentage: 75.0
        )
        
        // When/Then
        XCTAssertEqual(sut.stats.accuracyPercentage, 75.0, accuracy: 0.01)
    }
    
    func testAccuracyPercentage_ReturnsZeroWhenNoQuestions() {
        // Given - no stats updated
        
        // When/Then
        XCTAssertEqual(sut.stats.accuracyPercentage, 0.0)
    }
    
    // MARK: - Recent Score Tests
    
    func testHasRecentGames_ReturnsFalseInitially() {
        // Given - no games played
        
        // When/Then
        XCTAssertFalse(sut.hasRecentGames())
    }
    
    func testGetRecentGamesCount_ReturnsZeroInitially() {
        // Given - no games played
        
        // When/Then
        XCTAssertEqual(sut.getRecentGamesCount(), 0)
    }
    
    func testGetAverageRecentScore_ReturnsZeroInitially() {
        // Given - no games played
        
        // When/Then
        XCTAssertEqual(sut.getAverageRecentScore(), 0.0)
    }
}

