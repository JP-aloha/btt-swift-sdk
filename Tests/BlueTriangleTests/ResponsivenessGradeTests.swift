//
//  ResponsivenessGradeTests.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class ResponsivenessGradeTests: XCTestCase {

    func testGoodWhenAllCriteriaAreBelowThreshold() {
        let grade = ResponsivenessGradeMock.grade(hitchTimeRatio: 4, hangCount: 0, longestHang: 0)
        XCTAssertEqual(grade, .good)
    }

    func testBadWhenHitchTimeRatioAtLowerBoundary() {
        let grade = ResponsivenessGradeMock.grade(hitchTimeRatio: 5, hangCount: 0, longestHang: 0)
        XCTAssertEqual(grade, .bad)
    }

    func testWorstWhenHitchTimeRatioAboveUpperBoundary() {
        let grade = ResponsivenessGradeMock.grade(hitchTimeRatio: 11, hangCount: 0, longestHang: 0)
        XCTAssertEqual(grade, .worst)
    }

    func testBadWhenExactlyOneHang() {
        let grade = ResponsivenessGradeMock.grade(hitchTimeRatio: 0, hangCount: 1, longestHang: 0)
        XCTAssertEqual(grade, .bad)
    }

    func testWorstWhenTwoOrMoreHangs() {
        let grade = ResponsivenessGradeMock.grade(hitchTimeRatio: 0, hangCount: 2, longestHang: 0)
        XCTAssertEqual(grade, .worst)
    }

    func testBadWhenLongestHangIsAboveZero() {
        let grade = ResponsivenessGradeMock.grade(hitchTimeRatio: 0, hangCount: 0, longestHang: 1)
        XCTAssertEqual(grade, .bad)
    }

    func testWorstWhenLongestHangAboveUpperBoundary() {
        let grade = ResponsivenessGradeMock.grade(hitchTimeRatio: 0, hangCount: 0, longestHang: 2501)
        XCTAssertEqual(grade, .worst)
    }

    func testWorstWinsWhenOnlyOneCriterionIsWorst() {
        // hitchTimeRatio and longestHang are both "good"; hangCount alone pushes this to worst.
        let grade = ResponsivenessGradeMock.grade(hitchTimeRatio: 0, hangCount: 2, longestHang: 0)
        XCTAssertEqual(grade, .worst)
    }
}
