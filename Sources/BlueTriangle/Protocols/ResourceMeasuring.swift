//
//  ResourceUsageMeasuring.swift
//
//  Created by Mathew Gacy on 1/21/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

protocol ResourceUsageMeasuring {
    static func cpu() -> Double
    static func memory() -> UInt64
}

extension ResourceUsageMeasuring {
    static func measure() -> ResourceUsageMeasurement {
        .init(cpuUsage: cpu(),
              memoryUsage: memory())
    }
}
