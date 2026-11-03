//
//  ResponsivenessGradeCalculator.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import Foundation

/// Single source of truth for turning a screen's hitch/hang stats into one 0-100 badness score
/// (0=best, 100=worst). Used for the submit-time log line in `BlueTriangle`, by the Animation
/// Hitch example screen's debug HUD (via `@testable import`), and by `ResponsivenessGradeTests`.
enum ResponsivenessGradeCalculator {
   private static func severity(_ value: Float, good: Float, bad: Float, cap: Float) -> Float {
       let s1 = 30 * (value / good).clamped(to: 0...1)
       let s2 = 40 * ((value - good) / (bad - good)).clamped(to: 0...1)
       let s3 = 30 * ((value - bad) / (cap - bad)).clamped(to: 0...1)
       return s1 + s2 + s3
   }

   private static func combine(_ a: Float, _ b: Float) -> Float {
       let worse = max(a, b)
       let better = min(a, b)
       let weight: Float = 1 - (better / 100)
       return (worse + weight * better * (worse / 100)).clamped(to: 0...100)
   }

   // MARK: - Hitch Score
   static func hitchScore(hitchesSeverity: Double) -> Float {
       severity(Float(hitchesSeverity), good: 30, bad: 70, cap: 1000)
   }

   // MARK: - Hang Score
   static func hangScore(hangCount: Int64, longestHang: Millisecond) -> Float {
       max(
           severity(Float(hangCount), good: 2, bad: 5, cap: 100),
           severity(Float(longestHang), good: 1500, bad: 2500, cap: 100000)
       ).clamped(to: 0...100)
   }

   // MARK: - Final combined score
   static func grade(
       hitchesSeverity: Double,
       hangCount: Int64,
       longestHang: Millisecond
   ) -> Int {
       let hScore = hitchScore(hitchesSeverity: hitchesSeverity)
       let gScore = hangScore(hangCount: hangCount, longestHang: longestHang)
       let badness = combine(hScore, gScore).clamped(to: 0...100)
       return badness > 0 ? max(1, Int(badness)) : 0
   }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
