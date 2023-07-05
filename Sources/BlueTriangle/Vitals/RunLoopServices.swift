//
//  RunLoopServices.swift
//  MainThreadWatchDog
//
//  Created by jaiprakash bokhare on 14/03/23.
//

import Foundation

public enum RunLoopEvent{
    case TaskStart
    case TaskFinish
}

public struct Observing{
    let observer : CFRunLoopObserver
    let runloop  : CFRunLoop
}

public protocol RunloopRegistrationService{
    func registerObserver(runloop : CFRunLoop, eventObserver : @escaping (RunLoopEvent)->Void) throws -> Observing
    func unregisterObserver(o : Observing)
}


public class CFRunloopRegistrationService : RunloopRegistrationService{
    
    //private var createObserverHandler
    //private var addObserverHandler
    public init(){}
   public func registerObserver(runloop: CFRunLoop, eventObserver: @escaping (RunLoopEvent) -> Void) throws -> Observing {
        //make observer
        let CFObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault,
                                                            CFRunLoopActivity.allActivities.rawValue,
                                                            true,
                                                            0,
                                                            { observer, activity in
            //NSLog("Runloop Activity \(activity)")
            if let event = EventBuilder().setActivity(a: activity).build(){
                eventObserver(event)
            }
       })
        
        if let runloopObserver = CFObserver{
            let observing  = Observing(observer: runloopObserver, runloop: runloop)
        //register it
            CFRunLoopAddObserver(runloop,
                                 runloopObserver,
                                 CFRunLoopMode.commonModes)
            return observing
        }
        
        throw NSError(domain: "BTT-MainThreadObserver", code: 1)
    }
    
   public func unregisterObserver(o: Observing) {
        CFRunLoopRemoveObserver(o.runloop,
                                o.observer,
                                CFRunLoopMode.commonModes)
    }
    
    //TODO:: make static function activity translator ...
}

class EventBuilder{
    
    private var activity : CFRunLoopActivity?
    private var date : Date?
    
    func setActivity(a : CFRunLoopActivity) -> EventBuilder{
        activity = a
        date = Date()
        
        return self
    }
    
    func build() -> RunLoopEvent?{
        if activity == CFRunLoopActivity.entry ||
            activity == CFRunLoopActivity.afterWaiting ||
            activity == CFRunLoopActivity.beforeSources ||
            activity == CFRunLoopActivity.beforeTimers{
            return .TaskStart
        }
        else if activity == CFRunLoopActivity.exit ||
                    activity == CFRunLoopActivity.beforeWaiting{
            return .TaskFinish
        }
        
        return nil
    }
}
