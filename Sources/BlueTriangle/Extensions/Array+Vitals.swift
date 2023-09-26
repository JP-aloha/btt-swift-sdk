//
//  Array+Vitals.swift
//
//  Created by Mathew Gacy on 1/25/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension Array where Element == ResourceUsageMeasurement {
    func makeReport() -> PerformanceReport? {
        guard let initial = first else {
            return nil
        }
        
        let result = reduce(into: (cpu: Stats<Double>(min: initial.cpuUsage,
                                                      max: initial.cpuUsage,
                                                      cumulative: 0),
                                   memory: Stats<UInt64>(min: initial.memoryUsage,
                                                         max: initial.memoryUsage,
                                                         cumulative: 0))
        ) { result, element in
            result.cpu = update(stats: &result.cpu, with: element.cpuUsage)
            result.memory = update(stats: &result.memory, with: element.memoryUsage)
        }
        
        let avgCPU = result.cpu.cumulative / Double(count)
        let avgMemory = result.memory.cumulative / UInt64(count)
        return PerformanceReport(minCPU: Float(transportValue(result.cpu.min)),
                                 maxCPU: Float(transportValue(result.cpu.max)),
                                 avgCPU: Float(transportValue(avgCPU)),
                                 minMemory: result.memory.min,
                                 maxMemory: result.memory.max,
                                 avgMemory: avgMemory,
                                 maxMainThreadTask: 0)
    }
    
    private func transportValue(_ value : Double) ->Double{
        let activeProcessorCount = Double(ProcessInfo.processInfo.activeProcessorCount)
        return value / activeProcessorCount
    }
}

// MARK: - Supporting
typealias Stats<T: Numeric> = (min: T, max: T, cumulative: T)

func update(stats: inout Stats<Double>, with element: Double) -> Stats<Double> {
    if element < stats.min {
        stats.min = element
    } else if element > stats.max {
        stats.max = element
    }
    stats.cumulative += element
    return stats
}

func update(stats: inout Stats<UInt64>, with element: UInt64) -> Stats<UInt64> {
    if element < stats.min {
        stats.min = element
    } else if element > stats.max {
        stats.max = element
    }
    stats.cumulative += element
    return stats
}
