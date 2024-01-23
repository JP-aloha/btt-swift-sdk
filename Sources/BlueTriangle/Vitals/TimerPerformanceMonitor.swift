//
//  TimerPerformanceMonitor.swift
//
//  Created by Mathew Gacy on 1/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

final class TimerPerformanceMonitor: PerformanceMonitoring {
    enum State {
        case initial
        case started
        case ended
    }

    private let sampleInterval: TimeInterval
    private let resourceUsage: ResourceUsageMeasuring.Type
    private let runLoop: RunLoop
    private let mode: RunLoop.Mode
    private var cancellable: AnyCancellable?

    private(set) var measurements: [ResourceUsageMeasurement] = []
    private(set) var state: State = .initial

    var measurementCount: Int {
        measurements.count
    }

    init(
        sampleInterval: TimeInterval,
        resourceUsage: ResourceUsageMeasuring.Type,
        runLoop: RunLoop = .current,
        mode: RunLoop.Mode = .common
    ) {
        self.sampleInterval = sampleInterval
        self.resourceUsage = resourceUsage
        self.runLoop = runLoop
        self.mode = mode
    }

    func start() {
        if state == .started {
            return
        }
        cancellable = Timer.publish(every: sampleInterval, on: runLoop, in: mode)
            .autoconnect()
            .sink { [weak self] _ in
                self?.sample()
            }
        sample()
        state = .started
    }

    func end() {
        cancellable?.cancel()
        sample()
        state = .ended
    }

    func makeReport() -> PerformanceReport {
        measurements.makeReport() ?? .empty
    }

    // MARK: - Private

    private func sample() {
        let sample = resourceUsage.measure()
        NSLog("Measurement Sample \(sample)")
        measurements.append(sample)
    }
    
    var debugDescription: String{
        get{
            var memory = [UInt64]()
            var cpu = [Double]()
            let activeProcessorCount = Double(ProcessInfo.processInfo.activeProcessorCount)
            for measurement in measurements {
                memory.append(measurement.memoryUsage)
                cpu.append(measurement.cpuUsage / activeProcessorCount)
            }
            
            return "Memory Sample : PAGE NAME : \(memory) \n CPU Sample : PAGE NAME : \(cpu)"
        }
    }
}
