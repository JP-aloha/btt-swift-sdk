//
//  ResponsivenessReport.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import Foundation

struct ResponsivenessReport: Codable, Equatable {
    let hitchCount: Int64
    let totalHitchDuration: Millisecond
    let longestHitch: Millisecond
    let hangCount: Int64
    let totalHangDuration: Millisecond
    let longestHang: Millisecond
    let totalFrameCount: Int64
    let hitchHistograms: [HitchHistogramBucket]
    let hitchesSeverity: Double
}

extension ResponsivenessReport {
    static let empty: Self = .init(
        hitchCount: 0,
        totalHitchDuration: 0,
        longestHitch: 0,
        hangCount: 0,
        totalHangDuration: 0,
        longestHang: 0,
        totalFrameCount: 0,
        hitchHistograms: HitchHistogramBucket.makeDefaultBuckets(),
        hitchesSeverity: 0)

    /// The single 0-100 badness score for this report, via `ResponsivenessGradeCalculator`.
    var grade: Int {
        ResponsivenessGradeCalculator.grade(hitchesSeverity: hitchesSeverity, hangCount: hangCount, longestHang: longestHang)
    }

    /// JSON-encoded snapshot of every raw responsiveness field, sent as `NativeAppProperties.responsivenessMeta`.
    /// Only non-zero fields are included, mirroring `NativeAppProperties`'s own conditional encoding.
    var metaJSON: String? {
        struct Meta: Encodable {
            let hitchCount: Int64
            let totalHitchDuration: Millisecond
            let longestHitch: Millisecond
            let hangCount: Int64
            let totalHangDuration: Millisecond
            let longestHang: Millisecond
            let totalFrameCount: Int64
            let hitchHistograms: String
            let hitchesSeverity: Double

            enum CodingKeys: String, CodingKey {
                case hitchCount, totalHitchDuration, longestHitch, hangCount, totalHangDuration, longestHang, totalFrameCount, hitchHistograms, hitchesSeverity
            }

            func encode(to encoder: Encoder) throws {
                var con = encoder.container(keyedBy: CodingKeys.self)
                if hitchCount > 0 {
                    try con.encode(hitchCount, forKey: .hitchCount)
                }
                if totalHitchDuration > 0 {
                    try con.encode(totalHitchDuration, forKey: .totalHitchDuration)
                }
                if longestHitch > 0 {
                    try con.encode(longestHitch, forKey: .longestHitch)
                }
                if hangCount > 0 {
                    try con.encode(hangCount, forKey: .hangCount)
                }
                if totalHangDuration > 0 {
                    try con.encode(totalHangDuration, forKey: .totalHangDuration)
                }
                if longestHang > 0 {
                    try con.encode(longestHang, forKey: .longestHang)
                }
                if totalFrameCount > 0 {
                    try con.encode(totalFrameCount, forKey: .totalFrameCount)
                }
                if hitchCount > 0 {
                    try con.encode(hitchHistograms, forKey: .hitchHistograms)
                    try con.encode(hitchesSeverity, forKey: .hitchesSeverity)
                }
            }
        }
        let meta = Meta(
            hitchCount: hitchCount,
            totalHitchDuration: totalHitchDuration,
            longestHitch: longestHitch,
            hangCount: hangCount,
            totalHangDuration: totalHangDuration,
            longestHang: longestHang,
            totalFrameCount: totalFrameCount,
            hitchHistograms: HitchHistogramBucket.encodeCompact(hitchHistograms),
            hitchesSeverity: hitchesSeverity)
        guard let data = try? JSONEncoder().encode(meta) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

/// One bucket of a hitch-duration histogram — counts how many hitches had an excess duration
/// (`HitchClassifier.Classification.excessMs`, rounded to the nearest Ms) less than or equal to
/// `upperBoundMs` (and greater than the previous bucket's `upperBoundMs`).
struct HitchHistogramBucket: Codable, Equatable {
    let upperBoundMs: Millisecond
    var count: Int64
}

extension HitchHistogramBucket {
    static func makeDefaultBuckets() -> [HitchHistogramBucket] {
        [
            HitchHistogramBucket(upperBoundMs: 50, count: 0),
            HitchHistogramBucket(upperBoundMs: 150, count: 0),
            HitchHistogramBucket(upperBoundMs: 300, count: 0),
            HitchHistogramBucket(upperBoundMs: 450, count: 0),
            HitchHistogramBucket(upperBoundMs: 750, count: 0)
        ]
    }

    // Weights buckets of longer hitches more heavily for `weightedMean` below. Calculation-only —
    // not stored on the bucket itself, so it's never sent as part of any payload.
    private static let weightsByUpperBoundMs: [Millisecond: Double] = [
        50: 0.25,
        150: 0.75,
        300: 2.00,
        450: 2.50,
        750: 3.50
    ]

    static func weightedMean(_ buckets: [HitchHistogramBucket]) -> Double {
        let totalCount = buckets.reduce(into: 0) { $0 += $1.count }
        guard totalCount > 0 else { return 0 }
        let weightedSum = buckets.reduce(into: 0.0) { sum, bucket in
            sum += Double(bucket.count) * (weightsByUpperBoundMs[bucket.upperBoundMs] ?? 0)
        }
        return weightedSum
    }

    static func encodeCompact(_ buckets: [HitchHistogramBucket]) -> String {
        "[" + buckets.filter { $0.count > 0 }.map { "{\($0.upperBoundMs),\($0.count)}" }.joined(separator: ", ") + "]"
    }

    static func decodeCompact(_ string: String) -> [HitchHistogramBucket] {
        string
            .split(separator: "}")
            .compactMap { chunk -> HitchHistogramBucket? in
                let digits = chunk.filter { $0.isNumber || $0 == "," }
                let parts = digits.split(separator: ",")
                guard parts.count == 2,
                      let upperBoundMs = Millisecond(parts[0]),
                      let count = Int64(parts[1]) else { return nil }
                return HitchHistogramBucket(upperBoundMs: upperBoundMs, count: count)
            }
    }
}

/// Internal-only: read via `BlueTriangle.currentResponsivenessStats()` by the Animation Hitch
/// example screen's debug HUD (accessed there via `@testable import`), not part of the SDK's
/// public API.
final class BTResponsivenessStats: NSObject {
    let hitchCount: Int64
    let totalHitchDuration: Millisecond
    let longestHitch: Millisecond
    let hangCount: Int64
    let totalHangDuration: Millisecond
    let longestHang: Millisecond
    let totalFrameCount: Int64
    let fullTime: Millisecond
    let hitchHistograms: [HitchHistogramBucket]
    let hitchesSeverity: Double

    init(_ report: ResponsivenessReport?, fullTime: Millisecond = 0) {
        self.hitchCount = report?.hitchCount ?? 0
        self.totalHitchDuration = report?.totalHitchDuration ?? 0
        self.longestHitch = report?.longestHitch ?? 0
        self.hangCount = report?.hangCount ?? 0
        self.totalHangDuration = report?.totalHangDuration ?? 0
        self.longestHang = report?.longestHang ?? 0
        self.totalFrameCount = report?.totalFrameCount ?? 0
        self.fullTime = fullTime
        self.hitchHistograms = report?.hitchHistograms ?? HitchHistogramBucket.makeDefaultBuckets()
        self.hitchesSeverity = report?.hitchesSeverity ?? 0
    }
}
