//
//  BTTScreenLifecycleTracker.swift
//  
//
//  Created by Ashok Singh on 13/06/23.
//

import Foundation

protocol BTScreenLifecycleTracker{
    func loadStarted(_ id : String, _ name : String)
    func loadFinish(_ id : String, _ name : String)
    func viewStart(_ id : String, _ name : String)
    func viewingEnd(_ id : String, _ name : String)
}

class BTTScreenLifecycleTracker : BTScreenLifecycleTracker{
    
    static let shared = BTTScreenLifecycleTracker()
    private var btTimeActivityrMap = [String: TimerMapActivity]()
    
    func loadStarted(_ id: String, _ name: String) {
        self.manageTimer(name, id: id, type: .load)
    }
    
    func loadFinish(_ id: String, _ name: String) {
        self.manageTimer(name, id: id, type: .finish)
    }
    
    func viewStart(_ id: String, _ name: String) {
        self.manageTimer(name, id: id, type: .view)
    }
    
    func viewingEnd(_ id: String, _ name: String) {
        self.manageTimer(name, id: id, type: .disapear)
    }
    
    private func manageTimer(_ pageName : String, id : String, type : TimerMapType){
        let timerActivity = getTimerActivity(pageName, id: id)
        btTimeActivityrMap[id] = timerActivity
        timerActivity.manageTimeFor(type: type)
        if type == .disapear{
            btTimeActivityrMap.removeValue(forKey: id)
        }
    }
    
    private func getTimerActivity(_ pageName : String, id : String) -> TimerMapActivity{
        
        if let btTimerActivity = btTimeActivityrMap[id] {
            return btTimerActivity
        }else{
            let timerActivity = TimerMapActivity(pageName: pageName)
            return timerActivity
        }
    }
}

enum TimerMapType {
  case load, finish, view, disapear
}

class TimerMapActivity {
    
    private let timer : BTTimer
    private let pageName : String
    private var loadTime : TimeInterval?
    private var viewTime : TimeInterval?
    private var disapearTime : TimeInterval?
    
    init(pageName: String) {
        self.pageName = pageName
        self.timer = BlueTriangle.startTimer(page:Page(pageName: pageName))
    }
    
    func manageTimeFor(type : TimerMapType){
        
        if type == .load{
            loadTime = timeInterval
        }
        else if type == .finish{
            if loadTime == nil{
                loadTime = timeInterval
            }
        }
        else if type == .view{
            viewTime = timeInterval
        }
        else if type == .disapear{
            disapearTime = timeInterval
            self.submitTimer()
        }
    }
    
    func submitTimer(){
        
        if let viewTime = viewTime, let loadTime = loadTime, let disapearTime = disapearTime{
           
            timer.pageTimeBuilder = {
                return viewTime.milliseconds - loadTime.milliseconds
            }
            
            timer.nativeAppProperties = NativeAppProperties(
                fullTime: disapearTime.milliseconds - loadTime.milliseconds,
                loadTime: viewTime.milliseconds - loadTime.milliseconds,
                maxMainThreadUses: timer.performanceReport?.maxMainThreadTask.milliseconds ?? 0,
                viewType: .UIKit)
        }
        
        BlueTriangle.endTimer(timer)
    }
    
    private var timeInterval : TimeInterval{
        Date().timeIntervalSince1970
    }
}


