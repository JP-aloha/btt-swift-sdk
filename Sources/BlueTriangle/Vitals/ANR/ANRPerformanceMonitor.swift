//
//  File.swift
//  
//
//  Created by JP on 21/03/23.
//

import Foundation

public class ANRPerformanceMonitor : PerformanceMonitoring{
    var measurementCount: Int = 0
    
    func end() {
        stopTimer()
    }
    
    public func start(){
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
    

    public init(observer : ThreadTaskObserver = MainThreadObserver.sharedMainThreadObserver()){
        self.mainThreadObserver = observer
    }
    
    private var maxRunningTime : TimeInterval = 0
    private let mainThreadObserver : ThreadTaskObserver
    
    private var bgTimer : DispatchSourceTimer?
    private let timerDispatchQueue = DispatchQueue(label: "com.BTT.ANRWatchDogTimer"/*, attributes: .concurrent*/)
    
    private func startSampleTimer(){
        stopTimer()
        bgTimer = DispatchSource.makeTimerSource(queue: timerDispatchQueue)
        bgTimer?.schedule(deadline: DispatchTime.now(),
                          repeating: DispatchTimeInterval.seconds(1),
                          leeway: DispatchTimeInterval.never)
        bgTimer?.setEventHandler(handler: sampleTaskTime)
        bgTimer?.resume()
    }
    
    private func stopTimer(){
        if let timer = bgTimer{
            timer.cancel()
            bgTimer = nil
        }
    }
    
    private func sampleTaskTime(){
    
        if let currentSampleTime = mainThreadObserver.runningTask?.duration(), currentSampleTime > 1{
            //NSLog("Sample Main thread task : current task time : \(currentSampleTime)")
            if currentSampleTime > self.maxRunningTime{
                self.maxRunningTime = currentSampleTime
                self.measurementCount += 1
            }
        }else{
            //NSLog("Sample Main thread task : idle")
        }
    }
}
