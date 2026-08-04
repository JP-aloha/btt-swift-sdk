//
//  ResponsivenessGradeMock.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import Foundation


enum ResponsivenessGradeMock {

    /// Linearly interpolates `value` between [from, to] into the output
    /// range [outFrom, outTo]. Clamps if value is outside [from, to].
    private static func lerp(_ value: Double, from: Double, to: Double, outFrom: Double, outTo: Double) -> Double {
        guard to != from else { return outFrom }
        let t = min(1, max(0, (value - from) / (to - from)))
        return outFrom + t * (outTo - outFrom)
    }

    /// Continuous score for hitch rate, exact boundaries: <50 / 50-150 / >150
    private static func hitchScore(_ ratio: Double) -> Double {
        if ratio <= 50 {
            return lerp(ratio, from: 0, to: 50, outFrom: 100, outTo: 71)
        } else if ratio <= 150 {
            return lerp(ratio, from: 50, to: 150, outFrom: 70, outTo: 31)
        } else {
            return lerp(ratio, from: 150, to: 750, outFrom: 30, outTo: 1) // capped at 750
        }
    }

    /// Continuous score for hang count alone (used only for the >=2 "Worst" case;
    /// count==1 defers to longestHang, count==0 is a fixed 100 — see combine logic).
    private static func hangCountScore(_ count: Int) -> Double {
        guard count >= 2 else { return 100 }
        return lerp(Double(count), from: 2, to: 10, outFrom: 30, outTo: 1) // capped at 10 hangs
    }

    /// Continuous score for longest hang, exact boundary: <=2500 Bad, >2500 Worst.
    /// Only meaningful when hangCount > 0 — returns 100 if there's no hang at all.
    private static func longestHangScore(hangCount: Int, longestHang: Double) -> Double {
        guard hangCount > 0 else { return 100 }
        if longestHang <= 2500 {
            return lerp(longestHang, from: 0, to: 2500, outFrom: 70, outTo: 31)
        } else {
            return lerp(longestHang, from: 2500, to: 5000, outFrom: 30, outTo: 1) // capped at 5000ms
        }
    }

    /// Returns an exact 1-100 value — 100 = perfect, 1 = worst — reflecting
    /// precisely how far into its severity band each metric falls, not just
    /// which category it's in.
    static func score(hitchTimeRatio: Double, hangCount: Int, longestHang: Millisecond) -> Int {
        let hScore = hitchScore(hitchTimeRatio)
        let countScore = hangCountScore(hangCount)
        let hangScore = longestHangScore(hangCount: hangCount, longestHang: Double(longestHang))

        // Worst (lowest) score wins.
        let finalScore = min(hScore, countScore, hangScore)

        return Int(finalScore.rounded()).clamped(to: 1...100)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
