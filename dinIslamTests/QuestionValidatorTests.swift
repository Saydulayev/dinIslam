//
//  QuestionValidatorTests.swift
//  dinIslamTests
//

import XCTest
@testable import dinIslam

final class QuestionValidatorTests: XCTestCase {

    private var sut: QuestionValidator!

    override func setUp() {
        super.setUp()
        sut = QuestionValidator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Valid question

    func testValidate_validQuestion_doesNotThrow() throws {
        let question = makeQuestion(id: "q1", text: "Question?", answers: ["A", "B"], correctIndex: 0)
        try sut.validate([question])
    }

    func testIsValid_validQuestion_returnsTrue() {
        let question = makeQuestion(id: "q1", text: "Question?", answers: ["A", "B"], correctIndex: 0)
        XCTAssertTrue(sut.isValid(question))
    }

    // MARK: - Duplicate ID

    func testValidate_duplicateQuestionId_throwsDuplicateQuestionId() {
        let question = makeQuestion(id: "same", text: "Q?", answers: ["A", "B"], correctIndex: 0)
        do {
            try sut.validate([question, question])
            XCTFail("Expected ValidationError.duplicateQuestionId")
        } catch ValidationError.duplicateQuestionId(let questionId) {
            XCTAssertEqual(questionId, "same")
        } catch {
            XCTFail("Expected duplicateQuestionId, got \(error)")
        }
    }

    // MARK: - Empty text

    func testValidate_emptyQuestionText_throwsEmptyText() {
        let question = makeQuestion(id: "q1", text: "", answers: ["A", "B"], correctIndex: 0)
        assertThrows(expectedQuestionId: "q1") {
            try sut.validate([question])
        } match: { if case .emptyText = $0 { return true }; return false }
    }

    func testValidate_whitespaceOnlyQuestionText_throwsEmptyText() {
        let question = makeQuestion(id: "q1", text: "   \n\t  ", answers: ["A", "B"], correctIndex: 0)
        assertThrows(expectedQuestionId: "q1") {
            try sut.validate([question])
        } match: { if case .emptyText = $0 { return true }; return false }
    }

    // MARK: - Insufficient answers

    func testValidate_onlyOneAnswer_throwsInsufficientAnswers() {
        let question = makeQuestion(id: "q1", text: "Q?", answers: ["Only one"], correctIndex: 0)
        assertThrows(expectedQuestionId: "q1") {
            try sut.validate([question])
        } match: { if case .insufficientAnswers(_, let count) = $0 { return count == 1 }; return false }
    }

    // MARK: - correctIndex out of bounds

    func testValidate_correctIndexEqualToAnswersCount_throwsInvalidCorrectIndex() {
        let question = makeQuestion(id: "q1", text: "Q?", answers: ["A", "B"], correctIndex: 2)
        assertThrows(expectedQuestionId: "q1") {
            try sut.validate([question])
        } match: { if case .invalidCorrectIndex(_, let index, let count) = $0 { return index == 2 && count == 2 }; return false }
    }

    func testValidate_correctIndexGreaterThanAnswersCount_throwsInvalidCorrectIndex() {
        let question = makeQuestion(id: "q1", text: "Q?", answers: ["A", "B"], correctIndex: 5)
        assertThrows(expectedQuestionId: "q1") {
            try sut.validate([question])
        } match: { if case .invalidCorrectIndex = $0 { return true }; return false }
    }

    // MARK: - Negative correctIndex

    func testValidate_negativeCorrectIndex_throwsNegativeCorrectIndex() {
        let question = makeQuestion(id: "q1", text: "Q?", answers: ["A", "B"], correctIndex: -1)
        assertThrows(expectedQuestionId: "q1") {
            try sut.validate([question])
        } match: { if case .negativeCorrectIndex(_, let index) = $0 { return index == -1 }; return false }
    }

    // MARK: - Empty answer text

    func testValidate_emptyAnswerText_throwsEmptyAnswerText() {
        let question = makeQuestion(id: "q1", text: "Q?", answers: ["A", ""], correctIndex: 0)
        assertThrows(expectedQuestionId: "q1") {
            try sut.validate([question])
        } match: { if case .emptyAnswerText(_, let answerIndex) = $0 { return answerIndex == 1 }; return false }
    }

    func testValidate_whitespaceOnlyAnswerText_throwsEmptyAnswerText() {
        let question = makeQuestion(id: "q1", text: "Q?", answers: ["A", "  \t\n  "], correctIndex: 0)
        assertThrows(expectedQuestionId: "q1") {
            try sut.validate([question])
        } match: { if case .emptyAnswerText = $0 { return true }; return false }
    }

    // MARK: - Helpers

    private func makeQuestion(id: String, text: String, answers: [String], correctIndex: Int) -> Question {
        let answerModels = answers.enumerated().map { index, text in
            Answer(id: "\(id)-a\(index)", text: text)
        }
        return Question(
            id: id,
            text: text,
            answers: answerModels,
            correctIndex: correctIndex,
            category: "test",
            difficulty: .easy
        )
    }

    private func assertThrows(expectedQuestionId: String, block: () throws -> Void, match: (ValidationError) -> Bool) {
        do {
            try block()
            XCTFail("Expected ValidationError")
        } catch let error as ValidationError {
            XCTAssertTrue(match(error), "Unexpected error: \(error)")
        } catch {
            XCTFail("Expected ValidationError, got \(error)")
        }
    }
}
