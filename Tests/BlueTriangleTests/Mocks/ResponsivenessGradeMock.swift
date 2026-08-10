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

    private static func combine(_ a: Float, _ b: Float) -> Float {
        let worse = max(a, b)
        let better = min(a, b)
        let weight : Float = 1 - (better/100)
        return min(worse + weight * better * (worse / 100), 100)
    }

    // MARK: - Hitch Score
    static func hitchScore(hitchWeightedMean: Double) -> Float {
        min(Float(hitchWeightedMean), 90)
    }

    // MARK: - Hang Score
    static func hangScore(hangCount: Int64, longestHang: Millisecond) -> Float {
        let countScore = severity(Float(hangCount), good: 2, bad: 5, cap: 100)
        let durationScore = severity(Float(longestHang), good: 1500, bad: 2500, cap: 100000)
        return min(combine(countScore, durationScore), 90)
    }

    // MARK: - Final combined score
    static func grade(
        hitchWeightedMean: Double,
        hangCount: Int64,
        longestHang: Millisecond
    ) -> Int {
        let hScore = hitchScore(hitchWeightedMean: hitchWeightedMean)
        let gScore = hangScore(hangCount: hangCount, longestHang: longestHang)
        let badness = combine(hScore, gScore)
        return Int(badness.rounded()).clamped(to: 0...100)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
