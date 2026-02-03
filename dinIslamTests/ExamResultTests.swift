//
//  ExamResultTests.swift
//  dinIslamTests
//

import XCTest
@testable import dinIslam

final class ExamResultTests: XCTestCase {

    // MARK: - isPassed

    func testIsPassed_percentage70NoSkipped_returnsTrue() {
        let result = makeResult(percentage: 70.0, skippedQuestions: 0)
        XCTAssertTrue(result.isPassed)
    }

    func testIsPassed_percentage69NoSkipped_returnsFalse() {
        let result = makeResult(percentage: 69.0, skippedQuestions: 0)
        XCTAssertFalse(result.isPassed)
    }

    func testIsPassed_percentage70WithSkipped_returnsFalse() {
        let result = makeResult(percentage: 70.0, skippedQuestions: 1)
        XCTAssertFalse(result.isPassed)
    }

    func testIsPassed_highPercentageWithSkipped_returnsFalse() {
        let result = makeResult(percentage: 100.0, skippedQuestions: 2)
        XCTAssertFalse(result.isPassed)
    }

    func testIsPassed_percentageExactly70_noSkipped_returnsTrue() {
        let result = makeResult(percentage: 70.0, skippedQuestions: 0)
        XCTAssertTrue(result.isPassed)
    }

    // MARK: - grade

    func testGrade_percentage90_returnsExcellent() {
        let result = makeResult(percentage: 90.0)
        XCTAssertEqual(result.grade, .excellent)
    }

    func testGrade_percentage100_returnsExcellent() {
        let result = makeResult(percentage: 100.0)
        XCTAssertEqual(result.grade, .excellent)
    }

    func testGrade_percentage85_returnsGood() {
        let result = makeResult(percentage: 85.0)
        XCTAssertEqual(result.grade, .good)
    }

    func testGrade_percentage80_returnsGood() {
        let result = makeResult(percentage: 80.0)
        XCTAssertEqual(result.grade, .good)
    }

    func testGrade_percentage79_returnsSatisfactory() {
        let result = makeResult(percentage: 79.0)
        XCTAssertEqual(result.grade, .satisfactory)
    }

    func testGrade_percentage70_returnsSatisfactory() {
        let result = makeResult(percentage: 70.0)
        XCTAssertEqual(result.grade, .satisfactory)
    }

    func testGrade_percentage50_returnsUnsatisfactory() {
        let result = makeResult(percentage: 50.0)
        XCTAssertEqual(result.grade, .unsatisfactory)
    }

    func testGrade_percentage69_returnsUnsatisfactory() {
        let result = makeResult(percentage: 69.0)
        XCTAssertEqual(result.grade, .unsatisfactory)
    }

    // MARK: - Helpers

    private func makeResult(
        percentage: Double,
        skippedQuestions: Int = 0,
        totalQuestions: Int = 20
    ) -> ExamResult {
        let answered = totalQuestions - skippedQuestions
        let correct = Int(round(percentage / 100.0 * Double(totalQuestions)))
        let incorrect = max(0, answered - correct)
        return ExamResult(
            totalQuestions: totalQuestions,
            answeredQuestions: answered,
            skippedQuestions: skippedQuestions,
            correctAnswers: correct,
            incorrectAnswers: incorrect,
            timeExpiredQuestions: 0,
            totalTimeSpent: 0,
            averageTimePerQuestion: 0,
            percentage: percentage,
            configuration: .default,
            completedAt: Date()
        )
    }
}
