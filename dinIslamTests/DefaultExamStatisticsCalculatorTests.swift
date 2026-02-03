//
//  DefaultExamStatisticsCalculatorTests.swift
//  dinIslamTests
//

import XCTest
@testable import dinIslam

final class DefaultExamStatisticsCalculatorTests: XCTestCase {

    private var sut: DefaultExamStatisticsCalculator!

    override func setUp() {
        super.setUp()
        sut = DefaultExamStatisticsCalculator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - calculateCorrectAnswers

    func testCalculateCorrectAnswers_allCorrect_returnsCount() {
        let questions = [
            makeQuestion(id: "q1", correctIndex: 0),
            makeQuestion(id: "q2", correctIndex: 1),
        ]
        let answers: [String: ExamAnswer] = [
            "q1": ExamAnswer(questionId: "q1", selectedAnswerIndex: 0, correctAnswerIndex: 0, isSkipped: false, isTimeExpired: false),
            "q2": ExamAnswer(questionId: "q2", selectedAnswerIndex: 1, correctAnswerIndex: 1, isSkipped: false, isTimeExpired: false),
        ]
        XCTAssertEqual(sut.calculateCorrectAnswers(answers: answers, questions: questions), 2)
    }

    func testCalculateCorrectAnswers_mixedCorrectAndWrong_returnsOnlyCorrect() {
        let questions = [
            makeQuestion(id: "q1", correctIndex: 0),
            makeQuestion(id: "q2", correctIndex: 1),
        ]
        let answers: [String: ExamAnswer] = [
            "q1": ExamAnswer(questionId: "q1", selectedAnswerIndex: 0, correctAnswerIndex: 0, isSkipped: false, isTimeExpired: false),
            "q2": ExamAnswer(questionId: "q2", selectedAnswerIndex: 0, correctAnswerIndex: 1, isSkipped: false, isTimeExpired: false),
        ]
        XCTAssertEqual(sut.calculateCorrectAnswers(answers: answers, questions: questions), 1)
    }

    func testCalculateCorrectAnswers_skippedNotCounted() {
        let questions = [makeQuestion(id: "q1", correctIndex: 0)]
        let answers: [String: ExamAnswer] = [
            "q1": ExamAnswer(questionId: "q1", selectedAnswerIndex: 0, correctAnswerIndex: 0, isSkipped: true, isTimeExpired: false),
        ]
        XCTAssertEqual(sut.calculateCorrectAnswers(answers: answers, questions: questions), 0)
    }

    func testCalculateCorrectAnswers_timeExpiredNotCounted() {
        let questions = [makeQuestion(id: "q1", correctIndex: 0)]
        let answers: [String: ExamAnswer] = [
            "q1": ExamAnswer(questionId: "q1", selectedAnswerIndex: 0, correctAnswerIndex: 0, isSkipped: false, isTimeExpired: true),
        ]
        XCTAssertEqual(sut.calculateCorrectAnswers(answers: answers, questions: questions), 0)
    }

    func testCalculateCorrectAnswers_selectedAnswerIndexNil_notCountedAsCorrect() {
        let questions = [makeQuestion(id: "q1", correctIndex: 0)]
        let answers: [String: ExamAnswer] = [
            "q1": ExamAnswer(questionId: "q1", selectedAnswerIndex: nil, correctAnswerIndex: 0, isSkipped: false, isTimeExpired: false),
        ]
        XCTAssertEqual(sut.calculateCorrectAnswers(answers: answers, questions: questions), 0)
    }

    func testCalculateCorrectAnswers_emptyAnswers_returnsZero() {
        let questions = [makeQuestion(id: "q1", correctIndex: 0)]
        XCTAssertEqual(sut.calculateCorrectAnswers(answers: [:], questions: questions), 0)
    }

    func testCalculateCorrectAnswers_answerWithoutMatchingQuestion_notCounted() {
        let questions: [Question] = []
        let answers: [String: ExamAnswer] = [
            "q1": ExamAnswer(questionId: "q1", selectedAnswerIndex: 0, correctAnswerIndex: 0, isSkipped: false, isTimeExpired: false),
        ]
        XCTAssertEqual(sut.calculateCorrectAnswers(answers: answers, questions: questions), 0)
    }

    // MARK: - calculateSkippedAnswers

    func testCalculateSkippedAnswers_countSkippedAndTimeExpired() {
        let answers: [String: ExamAnswer] = [
            "q1": ExamAnswer(questionId: "q1", isSkipped: true, isTimeExpired: false),
            "q2": ExamAnswer(questionId: "q2", isSkipped: false, isTimeExpired: true),
            "q3": ExamAnswer(questionId: "q3", isSkipped: true, isTimeExpired: false),
        ]
        XCTAssertEqual(sut.calculateSkippedAnswers(answers: answers), 3)
    }

    func testCalculateSkippedAnswers_noSkipped_returnsZero() {
        let answers: [String: ExamAnswer] = [
            "q1": ExamAnswer(questionId: "q1", isSkipped: false, isTimeExpired: false),
        ]
        XCTAssertEqual(sut.calculateSkippedAnswers(answers: answers), 0)
    }

    func testCalculateSkippedAnswers_empty_returnsZero() {
        XCTAssertEqual(sut.calculateSkippedAnswers(answers: [:]), 0)
    }

    // MARK: - calculateAnsweredCount

    func testCalculateAnsweredCount_excludesSkippedAndTimeExpired() {
        let answers: [String: ExamAnswer] = [
            "q1": ExamAnswer(questionId: "q1", isSkipped: false, isTimeExpired: false),
            "q2": ExamAnswer(questionId: "q2", isSkipped: true, isTimeExpired: false),
            "q3": ExamAnswer(questionId: "q3", isSkipped: false, isTimeExpired: true),
        ]
        XCTAssertEqual(sut.calculateAnsweredCount(answers: answers), 1)
    }

    func testCalculateAnsweredCount_allAnswered_returnsCount() {
        let answers: [String: ExamAnswer] = [
            "q1": ExamAnswer(questionId: "q1", isSkipped: false, isTimeExpired: false),
            "q2": ExamAnswer(questionId: "q2", isSkipped: false, isTimeExpired: false),
        ]
        XCTAssertEqual(sut.calculateAnsweredCount(answers: answers), 2)
    }

    func testCalculateAnsweredCount_empty_returnsZero() {
        XCTAssertEqual(sut.calculateAnsweredCount(answers: [:]), 0)
    }

    // MARK: - Helpers

    private func makeQuestion(id: String, correctIndex: Int) -> Question {
        Question(
            id: id,
            text: "Question \(id)",
            answers: [
                Answer(id: "\(id)-a0", text: "A"),
                Answer(id: "\(id)-a1", text: "B"),
            ],
            correctIndex: correctIndex,
            category: "test",
            difficulty: .easy
        )
    }
}
