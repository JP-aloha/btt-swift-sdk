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
    private var totalFrameCount: Int64 = 0
    private var hitchCount: Int64 = 0
    private var totalHitchDuration: Double = 0
    private var longestHitch: Double = 0
    private var hangCount: Int64 = 0
    private var totalHangDuration: Double = 0
    private var longestHang: Double = 0
    private var hitchHistograms: [HitchHistogramBucket] = HitchHistogramBucket.makeDefaultBuckets()
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
        totalFrameCount = 0
        hitchCount = 0
        totalHitchDuration = 0
        longestHitch = 0
        hangCount = 0
        totalHangDuration = 0
        longestHang = 0
        hitchHistograms = HitchHistogramBucket.makeDefaultBuckets()

        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
        state = .started
    }

    func end() {
        flushPendingGapIfNeeded()
        displayLink?.invalidate()
        displayLink = nil
        state = .ended
    }

    private func flushPendingGapIfNeeded() {
        guard lastTimestamp != 0 else { return }
        let currentTime = now()
        let hangClassification = HangClassifier.classify(actual: currentTime - lastTimestamp, floorMs: hangFloorMs)
        guard hangClassification.isHang else { return }
        totalFrameCount += 1
        hangCount += 1
        totalHangDuration += hangClassification.durationMs
        longestHang = max(longestHang, hangClassification.durationMs)
        lastTimestamp = currentTime
    }

    func makeReport() -> ResponsivenessReport {
        flushPendingGapIfNeeded()
        return ResponsivenessReport(
            hitchCount: hitchCount,
            totalHitchDuration: Millisecond(totalHitchDuration.rounded()),
            longestHitch: Millisecond(longestHitch.rounded()),
            hangCount: hangCount,
            totalHangDuration: Millisecond(totalHangDuration.rounded()),
            longestHang: Millisecond(longestHang.rounded()),
            totalFrameCount: totalFrameCount,
            hitchHistograms: hitchHistograms,
            hitchesSeverity: HitchHistogramBucket.weightedMean(hitchHistograms))
    }

    @objc
    private func tick(_ link: CADisplayLink) {
        defer { lastTimestamp = link.timestamp }
        guard lastTimestamp != 0 else { return }
        processFrame(expected: link.targetTimestamp - link.timestamp, actual: link.timestamp - lastTimestamp)
    }

    func recordTick(at timestamp: CFTimeInterval) {
        lastTimestamp = timestamp
    }

    func processFrame(expected: CFTimeInterval, actual: CFTimeInterval) {
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
            longestHitch = max(longestHitch, classification.excessMs)
            incrementHitchHistogram(forExcessMs: classification.excessMs)
        }
    }

    // Buckets are ordered ascending by upperBoundMs, so the first bucket whose upperBoundMs is
    // at least the excess is the correct one (i.e. a bucket covers (previous upperBoundMs, upperBoundMs]).
    private func incrementHitchHistogram(forExcessMs excessMs: Double) {
        let excess = Millisecond(excessMs.rounded())
        for index in hitchHistograms.indices where excess <= hitchHistograms[index].upperBoundMs {
            hitchHistograms[index].count += 1
            return
        }
    }
}
#endif
