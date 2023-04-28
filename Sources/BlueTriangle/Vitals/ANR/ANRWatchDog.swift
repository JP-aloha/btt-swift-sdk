//
//  ANRWatchDog.swift
//  TimerRequest
//
//  Created by jaiprakash bokhare on 22/04/23.
//

import Foundation

public class ANRWatchDog{
    private let mainThreadObserver : MainThreadObserver
    let errorTriggerInterval : TimeInterval = 5
    let sampleTimeInterval : TimeInterval = 2
    
   public init(mainThreadObserver: MainThreadObserver = MainThreadObserver()) {
        self.mainThreadObserver = mainThreadObserver
        MainThreadTraceProvider.shared.setup()
    }
    
   public func start(){
        self.mainThreadObserver.start()
       startObservationTimer()
    }
    
   public func stop(){
        stopObservationTimer()
    }
    
    private var bgTimer : DispatchSourceTimer?
    private let timerDispatchQueue = DispatchQueue(label: "com.BTT.ANRWatchDogTimer"/*, attributes: .concurrent*/)

    private func startObservationTimer(){
        stopObservationTimer()
        bgTimer = DispatchSource.makeTimerSource(queue: timerDispatchQueue)
        bgTimer?.schedule(deadline: DispatchTime.now(),
                          repeating: DispatchTimeInterval.seconds(1),
                          leeway: DispatchTimeInterval.never)
        bgTimer?.setEventHandler(handler: checkRunningTaskDuration)
        bgTimer?.resume()
        //NSLog("\(#function)@\(#line)")
    }
    
    private var lastRaisedTask : ThreadTask?
    private func checkRunningTaskDuration(){
        //NSLog("\(#function)@\(#line) : \(mainThreadObserver.runningTask?.duration() ?? -1)")
        if let task = mainThreadObserver.runningTask, task.duration() > errorTriggerInterval{
            //NSLog("\(#function)@\(#line)")
            if lastRaisedTask === task{
                return //raise error only once for a task
            }
            
            raiseANRError()
            lastRaisedTask = task
        }
    }

    private func stopObservationTimer(){
        if let timer = bgTimer{
            timer.cancel()
            bgTimer = nil
        }
    }
    
    
    private func raiseANRError(){
        //TODO:: save as CrashReport in CrashReportPersistence
        //NSLog("\(#function)@\(#line)")
        print("------------ ANR Warning !! -----------")
        do{
            let trace = try MainThreadTraceProvider.shared.getTrace()
            print(trace)
        }catch{
            print("Error reading main thread Trace...")
        }
    }
}
