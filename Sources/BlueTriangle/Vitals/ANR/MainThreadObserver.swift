//
//  MainThreadObserver.swift
//  MainThreadWatchDog
//
//  Created by JP on 10/03/23.
//

import Foundation

public class ThreadTask {
    let startTime   : Date
    var endTime     : Date?
    
    init(startTime: Date) {
        self.startTime = startTime
        self.endTime = nil
    }
    
public func duration() -> TimeInterval{
        return  ((endTime ?? Date()).timeIntervalSince1970) - startTime.timeIntervalSince1970
    }
}

public protocol ThreadTaskObserver{
    func start()
    func stop()
    
    var runningTask : ThreadTask? {get}
}

private let __sharedObserver = MainThreadObserver()

public class MainThreadObserver : ThreadTaskObserver{
    
    public static func sharedMainThreadObserver() -> ThreadTaskObserver{
        return __sharedObserver
    }
    
    static func runningTaskDuration() -> TimeInterval?{
        return __sharedObserver.runningTask?.duration()
    }
    
    static func runningTask() -> ThreadTask?{
        return __sharedObserver.runningTask
    }
    
   public static func start(){
        __sharedObserver.start()
    }
    
    static func stop(){
        __sharedObserver.stop()
    }
    
    public private(set) var runningTask : ThreadTask?
    private let registrationService : RunloopRegistrationService
    private var observationToken : Observing?
    private var longRunningTask : ThreadTask?
    
    func getLongRunningTask() -> ThreadTask?{
        return self.runningTask?.duration() ?? 0 > self.longRunningTask?.duration() ?? 0 ? self.runningTask : self.longRunningTask
    }
    
   public init(registrationService: RunloopRegistrationService = CFRunloopRegistrationService()) {
        self.registrationService = registrationService
    }

   public func start(){
        
        //TODO:: Tasks Queue
        if observationToken == nil{
            do{
                self.observationToken = try self.registrationService.registerObserver(runloop: CFRunLoopGetMain(),
                                                                                      eventObserver: { [weak self] event in
                    //TODO:: Event Handler Queue
                    //NSLog("Event : \(event)")
                    switch event {
                    case .TaskStart:
                        if self?.runningTask == nil{
                            self?.runningTask = ThreadTask(startTime: Date())
                            //NSLog("MainThread Task Started")
                        }
                    case .TaskFinish:
                        self?.runningTask?.endTime = Date()
                        //NSLog("MainThread Task Finished After \(self?.runningTask?.duration() ?? -1)")
                        
                        if self?.runningTask?.duration() ?? 0 > self?.longRunningTask?.duration() ?? 0{
                            self?.longRunningTask = self?.runningTask
                        }
                        
                        self?.runningTask = nil
                    }
                })

                NSLog("StartedMainThreadObserver")
            }catch{
                NSLog("Error registering Main thread observer \(error)")
            }
        }
    }
    
   public func stop(){
        NSLog("Stoping MainThreadObserver...")
        //TODO:: Tasks Queue
        if let observing = self.observationToken{
            self.registrationService.unregisterObserver(o: observing)
            self.observationToken = nil
        }
    }
}
