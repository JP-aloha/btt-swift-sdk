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
    private var logger : Logging?
    var runningTask: ThreadTask? { get{ queue.sync { _runningTask} } }
    
    init(registrationService: RunloopRegistrationService = CFRunloopRegistrationService()) {
        self.registrationService = registrationService
    }
    
    func setUpLogger(_ logger : Logging){
        self.logger = logger
    }

    func start(){
        logger?.debug("Starting MainThreadObserver...")
        queue.sync {
            if observationToken == nil{
                registerObserver()
            }else{
                logger?.debug("Skipping Start MainThreadObserver already running...")
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
            
            logger?.debug("Started MainThreadObserver...")
        }catch{
            logger?.error("Error registering MainThreadObserver \(error)")
        }
    }
    
    func stop(){
        self.logger?.debug("Stoping MainThreadObserver...")
        queue.async {
            if let observing = self.observationToken{
                self.registrationService.unregisterObserver(o: observing)
                self.observationToken = nil
                self._runningTask = nil
                self.logger?.debug("Started MainThreadObserver...")
            }else{
                self.logger?.debug("Stop MainThreadObserver skipped observer not started ...")
            }
        }
    }
}

extension MainThreadObserver{
    static let live: MainThreadObserver = {
        MainThreadObserver()
    }()
}
