//
//  MainThreadObserver.swift
//  MainThreadWatchDog
//
//  Created by JP on 10/03/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

class ThreadTask {
    let startTime   : Date
    var endTime     : Date?
    
    init(startTime: Date) {
        self.startTime = startTime
        self.endTime = nil
    }
    
    func duration() -> TimeInterval{
        return  ((endTime ?? Date()).timeIntervalSince1970) - startTime.timeIntervalSince1970
    }
}

protocol ThreadTaskObserver{
    func start()
    func stop()
    
    var runningTask : ThreadTask? {get}
}

class MainThreadObserver : ThreadTaskObserver{
    
    private(set) var runningTask : ThreadTask?
    private let registrationService : RunloopRegistrationService
    private var observationToken : Observing?
    
    init(registrationService: RunloopRegistrationService = CFRunloopRegistrationService()) {
        self.registrationService = registrationService
    }

    func start(){
        
        if observationToken == nil{
            do{
                self.observationToken = try self.registrationService.registerObserver(runloop: CFRunLoopGetMain(),
                                                                                      eventObserver: { [weak self] event in
                    switch event {
                    case .TaskStart:
                        if self?.runningTask == nil{
                            self?.runningTask = ThreadTask(startTime: Date())
                        }
                    case .TaskFinish:
                        self?.runningTask?.endTime = Date()
                        self?.runningTask = nil
                    }
                })
            }catch{
                NSLog("Error registering Main thread observer \(error)")
            }
        }
    }
    
    func stop(){
        NSLog("Stoping MainThreadObserver...")
        if let observing = self.observationToken{
            self.registrationService.unregisterObserver(o: observing)
            self.observationToken = nil
        }
    }
}

extension MainThreadObserver{
    static let live: MainThreadObserver = {
        MainThreadObserver()
    }()
}
