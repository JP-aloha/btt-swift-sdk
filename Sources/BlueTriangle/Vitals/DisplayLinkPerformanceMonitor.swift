//
//  DisplayLinkPerformanceMonitor.swift
//
//  Created by Mathew Gacy on 1/19/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

#if os(iOS) || os(tvOS)
import Foundation
import UIKit

final class DisplayLinkPerformanceMonitor: PerformanceMonitoring {
    public enum State {
        case initial
        case started
        case paused
        case ended
    }

    enum Action {
        case start
        case pause
        case end
    }

    private let minimumFrameRate: CFTimeInterval = 50
    private let minimumSampleInterval: CFTimeInterval
    private let resourceUsage: ResourceUsageMeasuring.Type
    private var displayLink: CADisplayLink!
    private var lastSampleTimestamp: CFTimeInterval = .zero
    private(set) var measurements: [ResourceUsageMeasurement] = []
    private(set) var state: State = .initial
    let mainThreadPerformanceMonitor: PerformanceMonitoring?
    
    var measurementCount: Int {
        measurements.count
    }

    init(
        minimumSampleInterval: CFTimeInterval,
        resourceUsage: ResourceUsageMeasuring.Type,
        runLoop: RunLoop = .main,
        mode: RunLoop.Mode = .common
    ) {
        self.minimumSampleInterval = minimumSampleInterval
        self.resourceUsage = resourceUsage
        self.mainThreadPerformanceMonitor = ANRPerformanceMonitor()
        let displayLink = CADisplayLink(target: self, selector: #selector(step(displayLink:)))
        displayLink.isPaused = true
        displayLink.add(to: runLoop, forMode: mode)
        self.displayLink = displayLink
    }

    deinit {
        if state != .ended {
            displayLink.invalidate()
        }
    }

    func start() {
        handle(.start)
        mainThreadPerformanceMonitor?.start()
    }

    func end() {
        handle(.end)
        mainThreadPerformanceMonitor?.end()
    }

    func makeReport() -> PerformanceReport {
        var report = measurements.makeReport() ?? .empty
        report.maxMainThreadTask = mainThreadPerformanceMonitor?.makeReport().maxMainThreadTask ?? 0
        return report
    }

    private func handle(_ action: Action) {
        switch (state, action) {
        case (.initial, .start):
            displayLink.isPaused = false
            state = .started
        case (.started, .pause):
            displayLink.isPaused = true
            state = .paused
        case (.started, .end), (.paused, .end):
            displayLink.invalidate()
            sample()
            state = .ended
        default:
            break
        }
    }

    @objc
    private func step(displayLink: CADisplayLink) {
        guard displayLink.timestamp - lastSampleTimestamp > minimumSampleInterval else {
            return
        }
        guard 1 / (displayLink.targetTimestamp - displayLink.timestamp) > minimumFrameRate else {
            handle(.pause)
            return
        }
        sample()
    }

    private func sample() {
        lastSampleTimestamp = displayLink.timestamp
        measurements.append(resourceUsage.measure())
    }
}

#endif
