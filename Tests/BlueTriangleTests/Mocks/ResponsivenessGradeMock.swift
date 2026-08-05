//
//  ResponsivenessGradeMock.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import Foundation

enum ResponsivenessGradeMock {
    
    /// Explicit banded severity/badness curve: 0=best, 100=worst.
    private static func severity(_ value: Float, good: Float, bad: Float, cap: Float) -> Float {
        guard value > 0 else { return 0 }
        if value <= good {
            return (value / good) * 30
        }
        if value <= bad {
            let t = (value - good) / (bad - good)
            return 30 + t * 40
        }
        if value <= cap {
            let t = (value - bad) / (cap - bad)
            return 70 + t * 30
        }
        return 100
    }

    // MARK: - Hitch Score
    static func hitchScore(hitchRatio: Float, hitchFramePercent: Float) -> Float {
        let ratioScore = severity(hitchRatio, good: 10, bad: 20, cap: 100)
        let framePercentScore = severity(hitchFramePercent, good: 10, bad: 20, cap: 100)
        return max(ratioScore, framePercentScore)   // worse of the two wins
    }

    // MARK: - Hang Score
    static func hangScore(hangCount: Int, longestHang: Millisecond) -> Float {
        let countScore = severity(Float(hangCount), good: 2, bad: 5, cap: 100)
        let durationScore = severity(Float(longestHang), good: 1500, bad: 2500, cap: 5000)
        return max(countScore, durationScore)
    }

    // MARK: - Final combined score
    static func grade(
        hitchRatio: Float,
        hitchFramePercent: Float,
        hangCount: Int,
        longestHang: Millisecond
    ) -> Int {
        let hScore = hitchScore(hitchRatio: hitchRatio, hitchFramePercent: hitchFramePercent)
        let gScore = hangScore(hangCount: hangCount, longestHang: longestHang)
        let badness = max(hScore, gScore)      // 0=best, 100=worst
        return Int(badness.rounded()).clamped(to: 0...100)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
