//
//  File.swift
//  
//
//  Created by JP on 21/03/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

class ANRPerformanceMonitor : PerformanceMonitoring{
    var measurementCount: Int = 0
    let logger: Logging
    private var maxRunningTime      : TimeInterval = 0
    private let mainThreadObserver  : ThreadTaskObserver
    private var bgTimer             : DispatchSourceTimer?
    private let timerDispatchQueue  = DispatchQueue(label: "com.BTT.ANRWatchDogTimer")

    init(observer: ThreadTaskObserver = MainThreadObserver.live, logger: Logging = BTLogger.live){
        self.mainThreadObserver = observer
        self.logger = logger
    }

    func end() {
        stopTimer()
    }
    
    func start(){
        self.startSampleTimer()
    }

    func makeReport() -> PerformanceReport {
        PerformanceReport(minCPU: 0,
                          maxCPU: 0,
                          avgCPU: 0,
                          minMemory: 0,
                          maxMemory: 0,
                          avgMemory: 0,
        maxMainThreadTask: maxRunningTime)
    }
    
    private func startSampleTimer(){
        stopTimer()
        bgTimer = DispatchSource.makeTimerSource(queue: timerDispatchQueue)
        bgTimer?.schedule(deadline: DispatchTime.now(),
                          repeating: DispatchTimeInterval.seconds(1),
                          leeway: DispatchTimeInterval.never)
        bgTimer?.setEventHandler(handler: sampleTaskTime)
        bgTimer?.resume()
        
        logger.debug("ANRPerformanceMonitor: Started.")
    }
    
    private func stopTimer(){
        if let timer = bgTimer{
            timer.cancel()
            bgTimer = nil
            
            logger.debug("ANRPerformanceMonitor: Stopped.")
        }
    }
    
    private func sampleTaskTime(){
    
        if let currentSampleTime = mainThreadObserver.runningTask?.duration(), currentSampleTime > 1{
            self.maxRunningTime = max(currentSampleTime, self.maxRunningTime)
        }
    }
    
    public var debugDescription: String{
        get{
            return ""
        }
    }
}
