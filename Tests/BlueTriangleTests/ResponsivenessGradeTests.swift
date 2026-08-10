//
//  ResponsivenessGradeTests.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class ResponsivenessGradeTests: XCTestCase {

    // MARK: - Boundaries and caps

    func testAllMetricsAtZeroScoresBestPossible() {
        let score = ResponsivenessGradeMock.grade(hitchCount: 0, totalHitchDuration: 0, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 0)
    }

    func testBothHitchAxesAtGoodCeilingScoresThirty() {
        // hitchCount=75, totalHitchDuration=1500ms -> hitchDurationAvg=20ms, exactly the good
        // ceiling for BOTH axes at once (avg=20, total=1500).
        let score = ResponsivenessGradeMock.grade(hitchCount: 75, totalHitchDuration: 1500, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 30)
    }

    func testBothHitchAxesAtBadCeilingScoresSeventy() {
        // hitchCount=50, totalHitchDuration=2500ms -> hitchDurationAvg=50ms, exactly the bad
        // ceiling for BOTH axes at once.
        let score = ResponsivenessGradeMock.grade(hitchCount: 50, totalHitchDuration: 2500, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 70)
    }

    func testBothHitchAxesAtCapPinsAtOneHundred() {
        // hitchCount=50, totalHitchDuration=10000ms -> hitchDurationAvg=200ms, both at their cap.
        let score = ResponsivenessGradeMock.grade(hitchCount: 50, totalHitchDuration: 10_000, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 100)
    }

    // MARK: - min() gates the qualifying tier; max() (bounded to that tier) sets the displayed score

    func testHighAveragePerHitchAloneIsPinnedToGoodCeiling() {
        // A single 60ms hitch: hitchDurationAvg=60ms is past the Bad ceiling on its own, but
        // totalHitchDuration=60ms is deep in Good. min() gates the tier to Good (since not both
        // qualify for Bad), and max()-bounded-to-Good pins the displayed score at Good's ceiling
        // (30) rather than either the raw high average or the raw low total.
        let score = ResponsivenessGradeMock.grade(hitchCount: 1, totalHitchDuration: 60, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 30)
    }

    func testHighTotalDurationAloneIsPinnedToGoodCeiling() {
        // hitchCount=10000, totalHitchDuration=6000ms: totalHitchDuration alone is deep in Worst,
        // but hitchDurationAvg is only 0.6ms (deeply Good). Gated to Good, pinned at 30.
        let score = ResponsivenessGradeMock.grade(hitchCount: 10_000, totalHitchDuration: 6000, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 30)
    }

    func testAverageAtBadCeilingButTotalStillGoodPinsToGoodCeiling() {
        // hitchCount=2, totalHitchDuration=100ms: hitchDurationAvg=50ms (exactly Bad ceiling), but
        // totalHitchDuration=100ms is comfortably Good — gated to Good, pinned at 30.
        let score = ResponsivenessGradeMock.grade(hitchCount: 2, totalHitchDuration: 100, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 30)
    }

    func testBothWorstButUnequalDisplaysTheWorseValueUncapped() {
        // hitchCount=50, totalHitchDuration=2600ms: hitchDurationAvg=52ms (just past Bad, so
        // Worst-adjacent) and totalHitchDuration=2600ms (just past Bad too) — both qualify for
        // Worst, so the displayed score is the higher of the two, uncapped within Worst (70-100).
        let score = ResponsivenessGradeMock.grade(hitchCount: 50, totalHitchDuration: 2600, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 70)
    }

    // MARK: - Hang: unchanged, still driven by whichever axis is worse (no AND requirement)

    func testHangCountAtGoodCeilingScoresThirty() {
        let score = ResponsivenessGradeMock.grade(hitchCount: 0, totalHitchDuration: 0, hangCount: 2, longestHang: 0)
        XCTAssertEqual(score, 30)
    }

    func testHangCountAtBadCeilingScoresSeventy() {
        let score = ResponsivenessGradeMock.grade(hitchCount: 0, totalHitchDuration: 0, hangCount: 5, longestHang: 0)
        XCTAssertEqual(score, 70)
    }

    func testLongestHangAtCapPinsAtOneHundred() {
        let score = ResponsivenessGradeMock.grade(hitchCount: 0, totalHitchDuration: 0, hangCount: 1, longestHang: 100_000)
        XCTAssertEqual(score, 100)
    }

    func testSingleEightSecondHangDoesNotSaturateAtOneHundred() {
        // hangScore still uses max(), not the min-gated hitchScore approach — a single long hang
        // shouldn't be diluted by a Good hangCount.
        let score = ResponsivenessGradeMock.grade(hitchCount: 0, totalHitchDuration: 0, hangCount: 1, longestHang: 8030)
        let hangScoreAlone = ResponsivenessGradeMock.hangScore(hangCount: 1, longestHang: 8030)
        XCTAssertEqual(score, Int(hangScoreAlone.rounded()))
        XCTAssertEqual(score, 72)
    }

    // MARK: - Worked example

    func testBothHitchAndHangGoodEscalatesMildlyAtTheOuterCombine() {
        // hitchScore = 30 (both axes qualify for Good, pinned at ceiling), hangScore = 15
        // (hangCount=1, Good). The outer grade() still escalates two independently-elevated axes
        // via combine(), unlike the AND-gated hitchScore internals.
        let score = ResponsivenessGradeMock.grade(hitchCount: 75, totalHitchDuration: 1500, hangCount: 1, longestHang: 500)
        XCTAssertEqual(score, 34)
    }
}
