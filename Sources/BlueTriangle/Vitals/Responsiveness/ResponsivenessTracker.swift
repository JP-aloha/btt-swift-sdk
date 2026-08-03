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

    private var hitchCount = 0
    // Sum of excess ms (actual - expected) across all hitch events — NOT raw frame duration.
    private var totalHitchDuration: Double = 0
    // Raw duration (ms) of the single worst hitch frame — unlike totalHitchDuration, this is
    // actual duration, not excess.
    private var longestHitch: Double = 0

    private var hangCount = 0
    // Sum of raw duration (ms) across all hang events — hangs have no "expected" baseline to
    // subtract, unlike hitches, so this is a plain duration sum, not an excess sum.
    private var totalHangDuration: Double = 0
    private var longestHang: Double = 0

    // Injected so tests can drive a deterministic clock instead of real wall-clock time.
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
        hitchCount = 0
        totalHitchDuration = 0
        longestHitch = 0
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
        let hitchTimeRatio = Millisecond((elapsedSeconds > 0 ? totalHitchDuration / elapsedSeconds : 0).rounded())
        let hangTimeRatio = Millisecond((elapsedSeconds > 0 ? totalHangDuration / elapsedSeconds : 0).rounded())
        let roundedLongestHang = Millisecond(longestHang.rounded())

        return ResponsivenessReport(
            hitchCount: hitchCount,
            totalHitchDuration: Millisecond(totalHitchDuration.rounded()),
            longestHitch: Millisecond(longestHitch.rounded()),
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
            longestHitch = max(longestHitch, classification.durationMs)
        }
    }
}
#endif
