//
//  CapturedRequestCollectorMock.swift
//
//  Created by Mathew Gacy on 11/10/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import Foundation

actor CapturedRequestCollectorMock: CapturedRequestCollecting {
    var onStart: (Page, TimeInterval) -> Void
    var onCollectTimer: (InternalTimer, URLResponse?) -> Void
    var onCollectMetrics: (URLSessionTaskMetrics) -> Void

    init(
        onStart: @escaping (Page, TimeInterval) -> Void = { _, _ in },
        onCollectTimer: @escaping (InternalTimer, URLResponse?) -> Void = { _, _ in },
        onCollectMetrics: @escaping (URLSessionTaskMetrics) -> Void = { _ in }
    ) {
        self.onStart = onStart
        self.onCollectTimer = onCollectTimer
        self.onCollectMetrics = onCollectMetrics
    }
    
    func start(page: Page, startTime: TimeInterval){
        onStart(page, startTime)
    }

    func collect(metrics: URLSessionTaskMetrics, error : Error?){
        onCollectMetrics(metrics)
    }
    
    func collect(timer: InternalTimer, response: URLResponse?, method: String? = nil){
        onCollectTimer(timer, response)
    }
    
    func start(page: Page, startTime: TimeInterval, isGroupTimer: Bool) {}
    
    func update(pageName: String, startTime: Millisecond) {}
    
    func collect(timer: InternalTimer, response: CustomResponse){}
    
    func collect(timer: InternalTimer, request : URLRequest, error: Error?){}
}
