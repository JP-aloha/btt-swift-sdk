//
//  ResponsivenessGradeMock.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import Foundation

// Mirrors the app-side `ResponsivenessGrade` in Example-UIKit's AnimationHitchViewController.swift
// (the SDK itself no longer computes a grade — only the raw hitch/hang fields). Kept here so the
// grade specification is covered by an SDK-side test too, without the SDK depending on app code.
enum ResponsivenessGradeMock: Equatable {
    case good
    case bad
    case worst

    private var severity: Int {
        switch self {
        case .good: return 0
        case .bad: return 1
        case .worst: return 2
        }
    }

    static func grade(hitchTimeRatio: Millisecond, hangCount: Int, longestHang: Millisecond) -> ResponsivenessGradeMock {
        let ratioGrade: ResponsivenessGradeMock = hitchTimeRatio > 10 ? .worst : (hitchTimeRatio >= 5 ? .bad : .good)
        let countGrade: ResponsivenessGradeMock = hangCount >= 2 ? .worst : (hangCount == 1 ? .bad : .good)
        let longestHangGrade: ResponsivenessGradeMock = longestHang > 2500 ? .worst : (longestHang > 0 ? .bad : .good)
        return [ratioGrade, countGrade, longestHangGrade].max { $0.severity < $1.severity } ?? .good
    }
}
