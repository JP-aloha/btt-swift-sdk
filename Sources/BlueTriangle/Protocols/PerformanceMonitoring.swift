//
//  PerformanceMonitoring.swift
//
//  Created by Mathew Gacy on 1/11/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

protocol PerformanceMonitoring : CustomDebugStringConvertible {
    var measurementCount: Int { get }

    func start()
    func end()
    func makeReport() -> PerformanceReport
}

