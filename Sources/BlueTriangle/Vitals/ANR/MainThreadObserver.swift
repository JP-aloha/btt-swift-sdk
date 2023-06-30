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
    
    init(startTime: Date) {
        self.startTime  = startTime
    }
    
    func duration() -> TimeInterval{
        return  Date().timeIntervalSince1970 - startTime.timeIntervalSince1970
    }
}

protocol ThreadTaskObserver{
    func start()
    func stop()
    
    var runningTask : ThreadTask? {get}
}

class MainThreadObserver : ThreadTaskObserver{
    
    private var _runningTask : ThreadTask?
    private let registrationService : RunloopRegistrationService
    private var observationToken : Observing?
    private let queue : DispatchQueue = DispatchQueue(label: "MainThreadObserver.currentTaskQueue")
    var runningTask: ThreadTask? { get{ queue.sync { _runningTask} } }
    
    init(registrationService: RunloopRegistrationService = CFRunloopRegistrationService()) {
        self.registrationService = registrationService
    }

    func start(){
        NSLog("Starting MainThreadObserver...")
        queue.sync {
            if observationToken == nil{
                registerObserver()
            }else{
                NSLog("Skipping Start MainThreadObserver already running...")
            }
        }
    }
    
    private func registerObserver(){
        do{
            self.observationToken = try self.registrationService.registerObserver(runloop: CFRunLoopGetMain(),
                                                                                  eventObserver: { [weak self] event in
                switch event {
                case .TaskStart:
                    self?.queue.async {
                        if self?._runningTask == nil{
                            self?._runningTask = ThreadTask(startTime: Date())
                        }
                    }
                case .TaskFinish:
                    self?.queue.async {
                        self?._runningTask = nil
                    }
                }
            })
            
            NSLog("Started MainThreadObserver...")
        }catch{
            NSLog("Error registering MainThreadObserver \(error)")
        }
    }
    
    func stop(){
        NSLog("Stoping MainThreadObserver...")
        queue.async {
            if let observing = self.observationToken{
                self.registrationService.unregisterObserver(o: observing)
                self.observationToken = nil
                NSLog("Stoped MainThreadObserver...")
            }else{
                NSLog("Stop MainThreadObserver skipped observer not started ...")
            }
        }
    }
}

extension MainThreadObserver{
    static let live: MainThreadObserver = {
        MainThreadObserver()
    }()
}
