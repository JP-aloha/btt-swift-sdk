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
        XCTAssertEqual(report.longestHitch, 100) // the bigger of the two excesses (100ms, 50ms)
        XCTAssertEqual(report.totalFrameCount, 2)

        XCTAssertEqual(report.hangCount, 0)
        XCTAssertEqual(report.totalHangDuration, 0)
        XCTAssertEqual(report.longestHang, 0)
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
        XCTAssertEqual(report.totalFrameCount, 2)

        XCTAssertEqual(report.hitchCount, 0)
        XCTAssertEqual(report.totalHitchDuration, 0)
        XCTAssertEqual(report.longestHitch, 0)
    }

    func testHangFromBlockRightBeforeEndIsStillCaptured() {
        var currentTime: CFTimeInterval = 0
        let tracker = ResponsivenessTracker(now: { currentTime })
        tracker.start()
        currentTime = 0.016
        tracker.recordTick(at: currentTime) // a normal tick fires right before the block

        // Main thread blocked for 8s (e.g. a heavy synchronous task), then the screen is
        // dismissed immediately on unblocking — ending the timer before CADisplayLink gets
        // another run-loop turn to fire `tick` and record the gap itself.
        currentTime = 8.0
        tracker.end()

        let report = tracker.makeReport()
        XCTAssertEqual(report.hangCount, 1)
        XCTAssertEqual(report.longestHang, 7984) // 8.0s - 0.016s since the last recorded tick
        XCTAssertEqual(report.totalHangDuration, 7984)
    }

    func testHangFromBlockIsCapturedEvenWhenReportIsReadBeforeEnd() {
        // Group timers snapshot `makeReport()` for submission BEFORE calling `end()` on the
        // underlying timer — so the flush can't rely on `end()` alone.
        var currentTime: CFTimeInterval = 0
        let tracker = ResponsivenessTracker(now: { currentTime })
        tracker.start()
        currentTime = 0.016
        tracker.recordTick(at: currentTime)

        currentTime = 63.0 // e.g. a 63s main-thread block, as seen in a real submission
        let reportBeforeEnd = tracker.makeReport()
        XCTAssertEqual(reportBeforeEnd.hangCount, 1)
        XCTAssertEqual(reportBeforeEnd.longestHang, 62984)

        // A later end() (or another makeReport()) must not double-count the same gap.
        tracker.end()
        let reportAfterEnd = tracker.makeReport()
        XCTAssertEqual(reportAfterEnd.hangCount, 1)
        XCTAssertEqual(reportAfterEnd.longestHang, 62984)
    }

    func testRepeatedMakeReportPollingDoesNotInflateHitchCount() {
        // A debug HUD polling makeReport() on its own ~60Hz Timer isn't phase-locked with the
        // real CADisplayLink, so the gap since the last real tick is routinely a few ms of
        // ordinary jitter — flushPendingGapIfNeeded() must not misclassify that as a hitch.
        var currentTime: CFTimeInterval = 0
        let tracker = ResponsivenessTracker(now: { currentTime })
        tracker.start()
        currentTime = 0.016
        tracker.recordTick(at: currentTime)

        for _ in 0..<20 {
            currentTime += 0.005 // 5ms of polling jitter, well under both classifier floors
            _ = tracker.makeReport()
        }

        let report = tracker.makeReport()
        XCTAssertEqual(report.hitchCount, 0)
        XCTAssertEqual(report.hangCount, 0)
        XCTAssertEqual(report.totalFrameCount, 0)
    }

    func testVeryLongGapIsStillRecordedAsAHang() {
        var currentTime: CFTimeInterval = 0
        let tracker = ResponsivenessTracker(now: { currentTime })
        tracker.start()

        // 30s gap (e.g. a long main-thread block) -> no longer discarded, counted as one long hang
        tracker.processFrame(expected: 0.01, actual: 30.0)

        currentTime = 30.0
        let report = tracker.makeReport()

        XCTAssertEqual(report.hangCount, 1)
        XCTAssertEqual(report.totalHangDuration, 30000)
        XCTAssertEqual(report.longestHang, 30000)
    }
}
#endif
