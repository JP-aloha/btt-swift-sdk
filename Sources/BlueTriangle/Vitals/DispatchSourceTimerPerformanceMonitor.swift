//
//  DispatchSourceTimerPerformanceMonitor.swift
//
//  Created by Mathew Gacy on 2/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

final class DispatchSourceTimerPerformanceMonitor: PerformanceMonitoring {
    
    public enum State {
        case initial
        case started
        case ended
    }

    enum Action {
        case start
        case end
    }

    private let sampleInterval: TimeInterval
    private let resourceUsage: ResourceUsageMeasuring.Type
    private let queueQoS: DispatchQoS.QoSClass
    private let leeway: DispatchTimeInterval
    private let timerSourceFlags: DispatchSource.TimerFlags

    private lazy var timer: DispatchSourceTimer = {
        let queue = DispatchQueue.global(qos: queueQoS)
        // swiftlint:disable:next identifier_name
        let t = DispatchSource.makeTimerSource(flags: timerSourceFlags, queue: queue)
        t.schedule(deadline: .now(), repeating: sampleInterval, leeway: leeway)
        t.setEventHandler(handler: { [weak self] in
            self?.sample()
        })
        return t
    }()

    private(set) var measurements: [ResourceUsageMeasurement] = []
    private(set) var state: State = .initial

    var measurementCount: Int {
        measurements.count
    }

    // MARK: - Lifecycle

    init(
        sampleInterval: TimeInterval,
        resourceUsage: ResourceUsageMeasuring.Type,
        queueQoS: DispatchQoS.QoSClass = .userInitiated,
        leeway: DispatchTimeInterval = .microseconds(100),
        timerSourceFlags: DispatchSource.TimerFlags = []
    ) {
        self.sampleInterval = sampleInterval
        self.resourceUsage = resourceUsage
        self.queueQoS = queueQoS
        self.leeway = leeway
        self.timerSourceFlags = timerSourceFlags
    }

    deinit {
        if state == .started {
            timer.cancel()
        }
    }

    // MARK: - Interface

    func start() {
        handle(.start)
    }

    func end() {
        handle(.end)
    }

    func makeReport() -> PerformanceReport {
        measurements.makeReport() ?? .empty
    }

    // MARK: - Private

    private func handle(_ action: Action) {
        switch (state, action) {
        case (.initial, .start):
            timer.resume()
            state = .started
        case (.started, .end):
            timer.cancel()
            sample()
            state = .ended
        default:
            return
        }
    }

    private func sample() {
        measurements.append(resourceUsage.measure())
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
