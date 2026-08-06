//
//  ResponsivenessGradeTests.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class ResponsivenessGradeTests: XCTestCase {

    // MARK: - Worked examples

    func testAllMetricsWithinGoodBandsScoresGood() {
        // Both hitch sub-scores (8, 9) and both hang sub-scores (15, 10) are comfortably Good, so
        // combine()'s half-strength escalation barely moves them: hScore 9->9.36, gScore 15->15.75.
        // The final grade still takes the worse of the two (max), so it lands at 16, not 15.
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 1, longestHang: 500)
        XCTAssertEqual(score, 16)
    }

    func testHangCountJustAboveGoodCeilingPullsIntoBad() {
        // hangCount=3 is just past the good=2 ceiling, scoring 43.3 on its own; combining with the
        // Good durationScore (10) escalates gScore past hitchScore, so the final grade (max of
        // the two) lands on the escalated gScore.
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 3, longestHang: 500)
        XCTAssertEqual(score, 47)
    }

    func testLongestHangJustOverGoodCeilingPullsIntoBad() {
        // hangCount alone is Bad (43.3), longestHang=2000ms alone is Bad (50.0) — combining them
        // escalates gScore, which wins the final max() over hitchScore.
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 3, longestHang: 2000)
        XCTAssertEqual(score, 62)
    }

    func testManyShortHangsPushesIntoWorstViaCountAlone() {
        // 7 hangs, all short (<1500ms) — hangCount alone (70.6) crosses into Worst; combining
        // with the still-Good durationScore (10) escalates gScore further, which wins the final
        // max() over hitchScore.
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 7, longestHang: 500)
        XCTAssertEqual(score, 77)
    }

    func testHangCountWellAboveCeilingForcesWorstRegardlessOfDuration() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 11, longestHang: 500)
        XCTAssertEqual(score, 78)
    }

    func testSingleLongHangForcesWorstViaDurationAlone() {
        // 3 hangs is Bad on count alone (43.3); one hit 3000ms, Worst on duration alone (72.0,
        // now that longestHang's cap is 10000) — combining two already-bad sub-scores escalates
        // gScore, which wins the final max() over hitchScore.
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 3, longestHang: 3000)
        XCTAssertEqual(score, 90)
    }

    // MARK: - Boundaries and caps

    func testAllMetricsAtZeroScoresBestPossible() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 0, hitchFramePercent: 0, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 0)
    }

    func testHitchRatioAtGoodCeilingScoresThirty() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 15, hitchFramePercent: 0, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 30)
    }

    func testHitchRatioAtBadCeilingScoresSeventy() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 30, hitchFramePercent: 0, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 70)
    }

    func testHitchRatioAboveCapPinsAtOneHundred() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 500, hitchFramePercent: 0, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 100)
    }

    func testHitchFramePercentAloneCanDriveTheScoreWorseThanRatio() {
        // hitchRatio is Good (0), but hitchFramePercent=25 is Worst on its own — the max() wins.
        let score = ResponsivenessGradeMock.grade(hitchRatio: 0, hitchFramePercent: 25, hangCount: 0, longestHang: 0)
        let framePercentAlone = ResponsivenessGradeMock.hitchScore(hitchRatio: 0, hitchFramePercent: 25)
        XCTAssertEqual(score, Int(framePercentAlone.rounded()))
        XCTAssertEqual(score, 72)
    }

    func testHitchRatioExpectsPercentageNotRawMsPerSecondStat() {
        // stats.hitchTimePercent (Ms/s) must be converted to a percentage (÷ 10) by the caller
        // before reaching hitchScore/grade. A real-world 15% hitch rate is hitchTimePercent == 150
        // Ms/s — converted, that's exactly hitchRatio's Good/Bad boundary (score 30). Feeding the
        // raw, unconverted 150 straight in instead would hit this function's own cap (100) and
        // read as Worst — far too harsh — which is the bug this test pins down.
        let rawHitchTimeRatioMsPerSecond: Millisecond = 150
        let correctlyConvertedScore = ResponsivenessGradeMock.grade(
            hitchRatio: Float(rawHitchTimeRatioMsPerSecond) / 10,
            hitchFramePercent: 0,
            hangCount: 0,
            longestHang: 0)
        XCTAssertEqual(correctlyConvertedScore, 30)

        let incorrectlyUnconvertedScore = ResponsivenessGradeMock.grade(
            hitchRatio: Float(rawHitchTimeRatioMsPerSecond),
            hitchFramePercent: 0,
            hangCount: 0,
            longestHang: 0)
        XCTAssertEqual(incorrectlyUnconvertedScore, 100)
        XCTAssertNotEqual(correctlyConvertedScore, incorrectlyUnconvertedScore)
    }

    func testHitchRatioAndHitchFramePercentEachHitGoodCeilingAtTheirOwnThreshold() {
        // hitchRatio and hitchFramePercent have independent good/bad thresholds (15/30 vs
        // 10/20) — each reaches the Good/Bad boundary (score 30) at its own ceiling, and each
        // saturates at 100 well past its own cap.
        let ratioAtItsGoodCeiling = ResponsivenessGradeMock.hitchScore(hitchRatio: 15, hitchFramePercent: 0)
        let framePercentAtItsGoodCeiling = ResponsivenessGradeMock.hitchScore(hitchRatio: 0, hitchFramePercent: 10)
        XCTAssertEqual(ratioAtItsGoodCeiling, 30)
        XCTAssertEqual(framePercentAtItsGoodCeiling, 30)

        let ratioWellPastItsCap = ResponsivenessGradeMock.hitchScore(hitchRatio: 150, hitchFramePercent: 0)
        let framePercentWellPastItsCap = ResponsivenessGradeMock.hitchScore(hitchRatio: 0, hitchFramePercent: 105)
        XCTAssertEqual(ratioWellPastItsCap, 100)
        XCTAssertEqual(framePercentWellPastItsCap, 100)
    }

    func testLongestHangAboveCapPinsAtOneHundred() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 0, hitchFramePercent: 0, hangCount: 1, longestHang: 10000)
        XCTAssertEqual(score, 100)
    }

    func testHangCountAtGoodCeilingScoresThirty() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 0, hitchFramePercent: 0, hangCount: 2, longestHang: 0)
        XCTAssertEqual(score, 30)
    }

    func testHangCountAtBadCeilingScoresSeventy() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 0, hitchFramePercent: 0, hangCount: 5, longestHang: 0)
        XCTAssertEqual(score, 70)
    }
}
