//
//  PerformanceMonitorMock.swift
//
//  Created by Mathew Gacy on 9/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import Foundation

class PerformanceMonitorMock: PerformanceMonitoring {
    
    var report: PerformanceReport
    var onStart: () -> Void
    var onEnd: () -> Void
    var measurementCount: Int = 10

    init(
        report: PerformanceReport = Mock.performanceReport,
        onStart: @escaping () -> Void = { },
        onEnd: @escaping () -> Void = { }
    ) {
        self.report = report
        self.onStart = onStart
        self.onEnd = onEnd
    }

    func start() {
        onStart()
    }

    func end() {
        onEnd()
    }

    func makeReport() -> PerformanceReport {
        report
    }

    func reset() {
        report = Mock.performanceReport
        onStart = { }
        onEnd = { }
    }
    
    var debugDescription: String{
        get{
            return ""
        }
    }
}
