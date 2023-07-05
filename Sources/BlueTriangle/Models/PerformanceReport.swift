//
//  PerformanceReport.swift
//
//  Created by Mathew Gacy on 1/6/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct PerformanceReport: Codable, Equatable {
    let minCPU: Float
    let maxCPU: Float
    let avgCPU: Float
    let minMemory: UInt64
    let maxMemory: UInt64
    let avgMemory: UInt64
    var maxMainThreadTask: TimeInterval = 0
}

extension PerformanceReport {
    static let empty: Self = .init(
        minCPU: 0.0,
        maxCPU: 0.0,
        avgCPU: 0.0,
        minMemory: 0,
        maxMemory: 0,
        avgMemory: 0,
    maxMainThreadTask: 0)
}
