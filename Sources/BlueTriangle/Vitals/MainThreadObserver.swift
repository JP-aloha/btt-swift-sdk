//
//  MainThreadObserver.swift
//  MainThreadWatchDog
//
//  Created by jaiprakash bokhare on 10/03/23.
//

import Foundation

private let __mainObserver = MainThreadObserver()

class MainThreadObserver {
    
    static func runningTaskDuration() -> TimeInterval?{
        return __mainObserver.runningTask?.duration()
    }
    
    static func start(){
        __mainObserver.start()
    }
    
    struct Task {
        let startTime   : Date
        var endTime     : Date?
        var callStack   : String?
        
        func duration() -> TimeInterval{
            return  ((endTime ?? Date()).timeIntervalSince1970) - startTime.timeIntervalSince1970
        }
    }
    
    private(set) var runningTask : Task?
    private let registrationService : RunloopRegistrationService
    private var observationToken : Observing?
    private var longRunningTask : Task?{
        didSet{
            NSLog("MainThread Observer Long running task changed \(longRunningTask?.duration()) Sec.")
        }
    }
    
    func getLongRunningTask() -> Task?{
        return self.runningTask?.duration() ?? 0 > self.longRunningTask?.duration() ?? 0 ? self.runningTask : self.longRunningTask
    }
    
    init(registrationService: RunloopRegistrationService = CFRunloopRegistrationService()) {
        self.registrationService = registrationService
    }

    func start(){
        NSLog("Starting MainThreadObserver...")
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
                            self?.runningTask = Task(startTime: Date())
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
            }catch{
                NSLog("Error registering observer \(error)")
            }
            
            NSLog("StartedMainThreadObserver, Token: \(observationToken)")
        }
    }
    
    func stop(){
        NSLog("Stoping MainThreadObserver...")
        //TODO:: Tasks Queue
        if let observing = self.observationToken{
            self.registrationService.unregisterObserver(o: observing)
            self.observationToken = nil
        }
    }
}
