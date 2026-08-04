//
//  ResponsivenessGradeTests.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class ResponsivenessGradeTests: XCTestCase {

    // MARK: - Worked examples

    func testHangCountOneWithShortLongestHangIsMildlyBad() {
        // hangCount==1 defers entirely to longestHang; 900ms is well within the Bad band.
        let score = ResponsivenessGradeMock.score(hitchTimeRatio: 8.5, hangCount: 1, longestHang: 900)
        XCTAssertEqual(score, 56)
    }

    func testHangCountOneWithLongestHangNearTopOfBadBandScoresWorse() {
        // Same hangCount==1, but longestHang=2400ms sits near the top of the Bad band —
        // correctly much worse than the 900ms case even though both are technically "Bad".
        let score = ResponsivenessGradeMock.score(hitchTimeRatio: 8.5, hangCount: 1, longestHang: 2400)
        XCTAssertEqual(score, 33)
    }

    func testHangCountOneWithLongestHangAboveTwentyFiveHundredCrossesIntoWorst() {
        let score = ResponsivenessGradeMock.score(hitchTimeRatio: 8.5, hangCount: 1, longestHang: 3000)
        XCTAssertEqual(score, 24)
    }

    func testTwoShortHangsForceWorstViaCountAlone() {
        // hangCount==2 forces Worst via countScore even though the hangs themselves are short
        // (300ms, still within the Bad band on its own).
        let score = ResponsivenessGradeMock.score(hitchTimeRatio: 8.5, hangCount: 2, longestHang: 300)
        XCTAssertEqual(score, 30)
    }

    // MARK: - Perfect / boundary cases

    func testAllMetricsAtZeroScoresPerfect() {
        let score = ResponsivenessGradeMock.score(hitchTimeRatio: 0, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 100)
    }

    func testHitchTimeRatioAtFiftyBoundaryScoresSeventyOne() {
        let score = ResponsivenessGradeMock.score(hitchTimeRatio: 50, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 71)
    }

    func testHitchTimeRatioAtOneHundredFiftyBoundaryScoresThirtyOne() {
        let score = ResponsivenessGradeMock.score(hitchTimeRatio: 150, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 31)
    }

    func testHitchTimeRatioAboveThreeHundredCapIsClampedToOne() {
        let score = ResponsivenessGradeMock.score(hitchTimeRatio: 500, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 1)
    }

    func testHangCountAboveFiveCapIsClampedToOne() {
        let score = ResponsivenessGradeMock.score(hitchTimeRatio: 0, hangCount: 10, longestHang: 0)
        XCTAssertEqual(score, 1)
    }

    func testLongestHangAboveFiveThousandCapIsClampedToOne() {
        let score = ResponsivenessGradeMock.score(hitchTimeRatio: 0, hangCount: 1, longestHang: 10000)
        XCTAssertEqual(score, 1)
    }

    func testSingleHangWithZeroDurationScoresSeventy() {
        // hangCount>0 but longestHang==0 still costs points relative to no hang at all.
        let score = ResponsivenessGradeMock.score(hitchTimeRatio: 0, hangCount: 1, longestHang: 0)
        XCTAssertEqual(score, 70)
    }

    func testLongestHangIsIgnoredWhenHangCountIsZero() {
        // With hangCount==0, longestHang must have no bearing on the score even if it's huge —
        // the hangScore guard returns a perfect 100 regardless of longestHang's value.
        let scoreWithLargeLongestHang = ResponsivenessGradeMock.score(hitchTimeRatio: 100, hangCount: 0, longestHang: 5000)
        let scoreWithZeroLongestHang = ResponsivenessGradeMock.score(hitchTimeRatio: 100, hangCount: 0, longestHang: 0)
        XCTAssertEqual(scoreWithLargeLongestHang, 51)
        XCTAssertEqual(scoreWithZeroLongestHang, 51)
    }
}
