//
//  ResponsivenessReport.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import Foundation

struct ResponsivenessReport: Codable, Equatable {
    let hitchCount: Int
    let totalHitchDuration: Millisecond
    let hitchFramePercent: Float
    let hitchTimeRatio: Float
    let hangCount: Int
    let totalHangDuration: Millisecond
    let longestHang: Millisecond
    let hangTimeRatio: Float
}

extension ResponsivenessReport {
    static let empty: Self = .init(
        hitchCount: 0,
        totalHitchDuration: 0,
        hitchFramePercent: 0,
        hitchTimeRatio: 0,
        hangCount: 0,
        totalHangDuration: 0,
        longestHang: 0,
        hangTimeRatio: 0)
}

/// Internal-only: read via `BlueTriangle.currentResponsivenessStats()` by the Animation Hitch
/// example screen's debug HUD (accessed there via `@testable import`), not part of the SDK's
/// public API.
final class BTResponsivenessStats: NSObject {
    let hitchCount: Int
    let totalHitchDuration: Millisecond
    let hitchFramePercent: Float
    let hitchTimeRatio: Float
    let hangCount: Int
    let totalHangDuration: Millisecond
    let longestHang: Millisecond
    let hangTimeRatio: Float

    init(_ report: ResponsivenessReport?) {
        self.hitchCount = report?.hitchCount ?? 0
        self.totalHitchDuration = report?.totalHitchDuration ?? 0
        self.hitchFramePercent = report?.hitchFramePercent ?? 0
        self.hitchTimeRatio = report?.hitchTimeRatio ?? 0
        self.hangCount = report?.hangCount ?? 0
        self.totalHangDuration = report?.totalHangDuration ?? 0
        self.longestHang = report?.longestHang ?? 0
        self.hangTimeRatio = report?.hangTimeRatio ?? 0
    }
}
