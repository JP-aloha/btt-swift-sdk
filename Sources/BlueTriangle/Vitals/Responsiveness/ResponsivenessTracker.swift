//
//  ResponsivenessTracker.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

#if os(iOS) || os(tvOS)
import Foundation
import UIKit

enum HitchClassifier {
    struct Classification {
        let isHitch: Bool
        let durationMs: Double
        let excessMs: Double
    }

    static func classify(
        expected: CFTimeInterval,
        actual: CFTimeInterval,
        relativeTolerance: Double,
        absoluteFloorMs: Millisecond
    ) -> Classification {
        let durationMs = actual * 1000
        let excessMs = (actual - expected) * 1000
        let isHitch = actual > expected * relativeTolerance && excessMs > Double(absoluteFloorMs)
        return Classification(isHitch: isHitch, durationMs: durationMs, excessMs: excessMs)
    }
}

enum HangClassifier {
    struct Classification {
        let isHang: Bool
        let durationMs: Double
    }

    static func classify(actual: CFTimeInterval, floorMs: Millisecond) -> Classification {
        let durationMs = actual * 1000
        return Classification(isHang: durationMs > Double(floorMs), durationMs: durationMs)
    }
}

final class ResponsivenessTracker: ResponsivenessTracking {
    private enum State {
        case initial
        case started
        case ended
    }

    private let relativeTolerance: Double
    private let absoluteFloorMs: Millisecond
    private let hangFloorMs: Millisecond
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var state: State = .initial
    private var trackingStartTime: CFTimeInterval = 0
    private var totalFrameCount = 0
    private var hitchCount = 0
    private var totalHitchDuration: Double = 0
    private var hangCount = 0
    private var totalHangDuration: Double = 0
    private var longestHang: Double = 0
    private let now: () -> CFTimeInterval

    init(
        relativeTolerance: Double = Constants.Responsiveness.relativeTolerance,
        absoluteFloorMs: Millisecond = Constants.Responsiveness.absoluteFloorMs,
        hangFloorMs: Millisecond = Constants.Responsiveness.hangFloorMs,
        now: @escaping () -> CFTimeInterval = CACurrentMediaTime
    ) {
        self.relativeTolerance = relativeTolerance
        self.absoluteFloorMs = absoluteFloorMs
        self.hangFloorMs = hangFloorMs
        self.now = now
    }

    deinit {
        if state != .ended {
            displayLink?.invalidate()
        }
    }

    func start() {
        lastTimestamp = 0
        trackingStartTime = now()
        totalFrameCount = 0
        hitchCount = 0
        totalHitchDuration = 0
        hangCount = 0
        totalHangDuration = 0
        longestHang = 0

        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
        state = .started
    }

    func end() {
        displayLink?.invalidate()
        displayLink = nil
        state = .ended
    }

    func makeReport() -> ResponsivenessReport {
        let elapsedSeconds = now() - trackingStartTime
        let hitchTimeRatio = Float(elapsedSeconds > 0 ? (totalHitchDuration / elapsedSeconds) / 10 : 0)
        let hangTimeRatio = Float(elapsedSeconds > 0 ? (totalHangDuration / elapsedSeconds) / 10 : 0)
        let roundedLongestHang = Millisecond(longestHang.rounded())
        let hitchFramePercent = Float(totalFrameCount > 0 ? (Double(hitchCount) / Double(totalFrameCount)) * 100 : 0)

        return ResponsivenessReport(
            hitchCount: hitchCount,
            totalHitchDuration: Millisecond(totalHitchDuration.rounded()),
            hitchFramePercent: hitchFramePercent,
            hitchTimeRatio: hitchTimeRatio,
            hangCount: hangCount,
            totalHangDuration: Millisecond(totalHangDuration.rounded()),
            longestHang: roundedLongestHang,
            hangTimeRatio: hangTimeRatio)
    }

    @objc
    private func tick(_ link: CADisplayLink) {
        defer { lastTimestamp = link.timestamp }
        guard lastTimestamp != 0 else { return }
        processFrame(expected: link.targetTimestamp - link.timestamp, actual: link.timestamp - lastTimestamp)
    }

    // Accumulates one frame's expected/actual duration into the running hitch/hang totals.
    // Separated from `tick` (a test seam) since CADisplayLink's own timestamps aren't controllable.
    func processFrame(expected: CFTimeInterval, actual: CFTimeInterval) {
        guard actual * 1000 < Double(Constants.Responsiveness.maxRecordableGapMs) else { return }
        totalFrameCount += 1

        let hangClassification = HangClassifier.classify(actual: actual, floorMs: hangFloorMs)
        if hangClassification.isHang {
            hangCount += 1
            totalHangDuration += hangClassification.durationMs
            longestHang = max(longestHang, hangClassification.durationMs)
            return
        }

        let classification = HitchClassifier.classify(
            expected: expected,
            actual: actual,
            relativeTolerance: relativeTolerance,
            absoluteFloorMs: absoluteFloorMs)

        if classification.isHitch {
            hitchCount += 1
            totalHitchDuration += classification.excessMs
        }
    }
}
#endif
