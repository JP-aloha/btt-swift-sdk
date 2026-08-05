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
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 1, longestHang: 500)
        XCTAssertEqual(score, 15)
    }

    func testHangCountJustAboveGoodCeilingPullsIntoBad() {
        // hangCount=3 is just past the good=2 ceiling, scoring 43.3 on its own — worse than
        // hitchScore (12.6) — even though longestHang (500ms) is comfortably Good.
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 3, longestHang: 500)
        XCTAssertEqual(score, 43)
    }

    func testLongestHangJustOverGoodCeilingPullsIntoBad() {
        // hangCount alone is Bad (43.3), but longestHang=2000ms alone scores worse (50.0) —
        // the worse of the two wins.
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 3, longestHang: 2000)
        XCTAssertEqual(score, 50)
    }

    func testManyShortHangsPushesIntoWorstViaCountAlone() {
        // 7 hangs, all short (<1500ms) — hangCount alone (70.6) crosses into Worst even though
        // durationScore (10.7) is still Good.
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 7, longestHang: 500)
        XCTAssertEqual(score, 71)
    }

    func testHangCountWellAboveCeilingForcesWorstRegardlessOfDuration() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 11, longestHang: 500)
        XCTAssertEqual(score, 72)
    }

    func testSingleLongHangForcesWorstViaDurationAlone() {
        // Only 3 hangs (Bad on count alone), but one hit 3000ms — duration alone (76.0) wins.
        let score = ResponsivenessGradeMock.grade(hitchRatio: 4, hitchFramePercent: 3, hangCount: 3, longestHang: 3000)
        XCTAssertEqual(score, 76)
    }

    // MARK: - Boundaries and caps

    func testAllMetricsAtZeroScoresBestPossible() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 0, hitchFramePercent: 0, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 0)
    }

    func testHitchRatioAtGoodCeilingScoresThirty() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 10, hitchFramePercent: 0, hangCount: 0, longestHang: 0)
        XCTAssertEqual(score, 30)
    }

    func testHitchRatioAtBadCeilingScoresSeventy() {
        let score = ResponsivenessGradeMock.grade(hitchRatio: 20, hitchFramePercent: 0, hangCount: 0, longestHang: 0)
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
        // stats.hitchTimeRatio (Ms/s) must be converted to a percentage (÷ 10) by the caller
        // before reaching hitchScore/grade. A real-world 10% hitch rate is hitchTimeRatio == 100
        // Ms/s — converted, that's exactly the Good/Bad boundary (score 30). Feeding the raw,
        // unconverted 100 straight in instead would hit this function's own cap (100) and read
        // as Worst — 10x too harsh — which is the bug this test pins down.
        let rawHitchTimeRatioMsPerSecond: Millisecond = 100
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

    func testHitchRatioAndHitchFramePercentAreOnTheSameScale() {
        // Once hitchRatio has been converted from raw Ms/s to a percentage (÷10, done by the
        // caller), it lands on the exact same 0-100 scale as hitchFramePercent — so equivalent
        // percentages must score identically through hitchScore, at both the Good/Bad boundary
        // (10%) and comfortably past the Worst cap (105%).
        let tenPercentViaRatio = ResponsivenessGradeMock.hitchScore(hitchRatio: Float(100 as Millisecond) / 10, hitchFramePercent: 0)
        let tenPercentViaFramePercent = ResponsivenessGradeMock.hitchScore(hitchRatio: 0, hitchFramePercent: 10)
        XCTAssertEqual(tenPercentViaRatio, 30)
        XCTAssertEqual(tenPercentViaFramePercent, 30)
        XCTAssertEqual(tenPercentViaRatio, tenPercentViaFramePercent)

        let hundredFivePercentViaRatio = ResponsivenessGradeMock.hitchScore(hitchRatio: Float(1050 as Millisecond) / 10, hitchFramePercent: 0)
        let hundredFivePercentViaFramePercent = ResponsivenessGradeMock.hitchScore(hitchRatio: 0, hitchFramePercent: 105)
        XCTAssertEqual(hundredFivePercentViaRatio, 100)
        XCTAssertEqual(hundredFivePercentViaFramePercent, 100)
        XCTAssertEqual(hundredFivePercentViaRatio, hundredFivePercentViaFramePercent)
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
