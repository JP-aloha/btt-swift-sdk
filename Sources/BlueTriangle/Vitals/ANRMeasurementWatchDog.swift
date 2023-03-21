//
//  File.swift
//  
//
//  Created by JP on 21/03/23.
//

import Foundation

protocol ANRMeasurement{
    func start()
    func stop()
    
    var longestRunningTaskInterval : TimeInterval {get}
}

public class ANRMeasurementWatchDog{
    
    public func start(){
        self.startSampleTimer()
    }
    
    public init(observer : ThreadTaskObserver = MainThreadObserver.sharedMainThreadObserver()){
        self.mainThreadObserver = observer
    }
    
    private var maxRunningTime : TimeInterval = 0
    private let mainThreadObserver : ThreadTaskObserver
    
    private var bgTimer : DispatchSourceTimer?
    private let timerDispatchQueue = DispatchQueue(label: "com.BTT.ANRWatchDogTimer"/*, attributes: .concurrent*/)
    
    private func startSampleTimer(){
        // let queue = DispatchQueue(label: "com.BTT.ANRWatchDogTimer", attributes: .concurrent)
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
            NSLog("Sample Main thread task : current task time : \(currentSampleTime)")
            if currentSampleTime > self.maxRunningTime{
                self.maxRunningTime = currentSampleTime
            }
        }else{
            NSLog("Sample Main thread task : idle")
        }
    }
}
