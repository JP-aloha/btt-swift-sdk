//
//  ResponsivenessTrackerTests.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

#if os(iOS) || os(tvOS)
final class ResponsivenessTrackerTests: XCTestCase {

    func testHitchFramesReportEveryResponsivenessField() {
        var currentTime: CFTimeInterval = 0
        let tracker = ResponsivenessTracker(now: { currentTime })
        tracker.start()

        // Frame 1: 10ms expected vs 110ms actual -> 100ms excess (over the 3ms floor) -> hitch
        tracker.processFrame(expected: 0.01, actual: 0.11)
        // Frame 2: 10ms expected vs 60ms actual -> 50ms excess -> hitch
        tracker.processFrame(expected: 0.01, actual: 0.06)

        currentTime = 2.0 // 2 elapsed seconds since start()
        let report = tracker.makeReport()

        XCTAssertEqual(report.hitchCount, 2)
        XCTAssertEqual(report.totalHitchDuration, 150) // 100ms + 50ms excess
        XCTAssertEqual(report.longestHitch, 110) // longest raw frame duration, not excess
        XCTAssertEqual(report.hitchTimeRatio, 75) // 150ms excess / 2s elapsed

        XCTAssertEqual(report.hangCount, 0)
        XCTAssertEqual(report.totalHangDuration, 0)
        XCTAssertEqual(report.longestHang, 0)
        XCTAssertEqual(report.hangTimeRatio, 0)
    }

    func testHangFramesReportEveryResponsivenessField() {
        var currentTime: CFTimeInterval = 0
        let tracker = ResponsivenessTracker(now: { currentTime })
        tracker.start()

        // Frame 1: 800ms actual, over the 750ms hang floor -> hang
        tracker.processFrame(expected: 0.01, actual: 0.8)
        // Frame 2: 1200ms actual -> hang
        tracker.processFrame(expected: 0.01, actual: 1.2)

        currentTime = 2.0 // 2 elapsed seconds since start()
        let report = tracker.makeReport()

        XCTAssertEqual(report.hangCount, 2)
        XCTAssertEqual(report.totalHangDuration, 2000) // 800ms + 1200ms
        XCTAssertEqual(report.longestHang, 1200)
        XCTAssertEqual(report.hangTimeRatio, 1000) // 2000ms / 2s elapsed

        XCTAssertEqual(report.hitchCount, 0)
        XCTAssertEqual(report.totalHitchDuration, 0)
        XCTAssertEqual(report.longestHitch, 0)
        XCTAssertEqual(report.hitchTimeRatio, 0)
    }
}
#endif
