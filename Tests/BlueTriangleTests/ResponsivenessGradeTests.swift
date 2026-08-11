//
//  ResponsivenessGradeTests.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class ResponsivenessGradeTests: XCTestCase {

    // MARK: - Hitch: scored directly from the histogram's weighted mean

    func testAllMetricsAtZeroScoresBestPossible() {
        let score = ResponsivenessGradeCalculator.grade(hitchesSeverity: 0, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 0)
    }

    func testHitchScorePassesThroughDirectlyBelowCap() {
        XCTAssertEqual(ResponsivenessGradeCalculator.hitchScore(hitchesSeverity: 45), 45)
    }

    func testHitchScoreAtCapIsOneHundred() {
        // hitchScore bands its input via severity(good: 30, bad: 70, cap: 1000) — the cap is 1000,
        // not 100, so it takes a value at that cap to read as a full 100.
        XCTAssertEqual(ResponsivenessGradeCalculator.hitchScore(hitchesSeverity: 1000), 100)
    }

    func testHitchScoreAboveCapIsClampedToOneHundred() {
        XCTAssertEqual(ResponsivenessGradeCalculator.hitchScore(hitchesSeverity: 2000), 100)
    }

    func testHitchAloneWithoutHangProducesUnescalatedScore() {
        // better == 0 in combine(), so the outer grade equals hitchScore untouched.
        let score = ResponsivenessGradeCalculator.grade(hitchesSeverity: 40, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 40)
    }

    func testHitchAloneCanReachFullOneHundred() {
        let score = ResponsivenessGradeCalculator.grade(hitchesSeverity: 1000, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 100)
    }

    // MARK: - Hang: driven by whichever axis (count or duration) is worse

    func testHangCountAtGoodCeilingScoresThirty() {
        let score = ResponsivenessGradeCalculator.grade(hitchesSeverity: 0, hangCount: 2, longestHang: 0)
        XCTAssertEqual(score, 30)
    }

    func testHangCountAtBadCeilingScoresSeventy() {
        let score = ResponsivenessGradeCalculator.grade(hitchesSeverity: 0, hangCount: 5, longestHang: 0)
        XCTAssertEqual(score, 70)
    }

    func testLongestHangAtCapReachesOneHundred() {
        let score = ResponsivenessGradeCalculator.grade(hitchesSeverity: 0, hangCount: 0, longestHang: 100_000)
        XCTAssertEqual(score, 100)
    }

    func testSingleEightSecondHangDoesNotSaturateAtOneHundred() {
        // hangScore uses max(), not an AND-gated approach — a single long hang shouldn't be
        // diluted by a Good hangCount. grade() truncates rather than rounds, so this matches
        // Int(hangScoreAlone), not Int(hangScoreAlone.rounded()).
        let score = ResponsivenessGradeCalculator.grade(hitchesSeverity: 0, hangCount: 1, longestHang: 8030)
        let hangScoreAlone = ResponsivenessGradeCalculator.hangScore(hangCount: 1, longestHang: 8030)
        XCTAssertEqual(score, Int(hangScoreAlone))
        XCTAssertEqual(score, 71)
    }

    // MARK: - combine(): the worse axis sets the base; the better axis still nudges it further

    func testBothHitchAndHangGoodEscalatesMildlyAtTheOuterCombine() {
        // hitchScore = 30, hangScore = 15 (hangCount=1, longestHang=500, both Good). combine()
        // still escalates two independently-elevated axes rather than just taking the max, and
        // grade() truncates the result (33.825 -> 33) rather than rounding it.
        let score = ResponsivenessGradeCalculator.grade(hitchesSeverity: 30, hangCount: 1, longestHang: 500)
        XCTAssertEqual(score, 33)
    }

    func testBothHitchAndHangBadEscalatesWellBeyondEitherAlone() {
        // hitchScore ≈ 70.32 (80 compressed by the good:30/bad:70/cap:1000 banding), hangScore = 70
        // (hangCount=5, Bad ceiling) — neither alone reaches 90, but combine() pushes the pair to 85.
        let score = ResponsivenessGradeCalculator.grade(hitchesSeverity: 80, hangCount: 5, longestHang: 0)
        XCTAssertEqual(score, 85)
    }

    func testBothAxesAtCapCombineToExactlyOneHundred() {
        let score = ResponsivenessGradeCalculator.grade(hitchesSeverity: 200, hangCount: 1, longestHang: 200_000)
        XCTAssertEqual(score, 100)
    }
}
