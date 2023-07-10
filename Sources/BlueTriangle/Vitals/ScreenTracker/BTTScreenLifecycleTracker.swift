//
//  BTTScreenLifecycleTracker.swift
//  
//
//  Created by JP on 13/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//


import Foundation


#if canImport(UIKit)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif


protocol BTScreenLifecycleTracker{
    func loadStarted(_ id : String, _ name : String)
    func loadFinish(_ id : String, _ name : String)
    func viewStart(_ id : String, _ name : String)
    func viewingEnd(_ id : String, _ name : String)
}

class BTTScreenLifecycleTracker : BTScreenLifecycleTracker{
    
    static let shared = BTTScreenLifecycleTracker()
    private var btTimeActivityrMap = [String: TimerMapActivity]()
    private var enableLifecycleTracker = false
    private var viewType = ViewType.UIKit
    private(set) var logger : Logging?
    private var startTimerPages = [String : String]()
    
    private init() {
        registerAppForegroundAndBackgroundNotification()
    }
    
    func setUpLogger(_ logger : Logging){
        self.logger = logger
    }
    
    func setLifecycleTracker(_ enable : Bool){
        self.enableLifecycleTracker = enable
    }
    
    func setUpViewType(_ type : ViewType){
        self.viewType = type
    }
    
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
        self.logger?.info("View tracker timer submited for screen :\(name)")
        self.manageTimer(name, id: id, type: .disapear)
    }
    
    private func manageTimer(_ pageName : String, id : String, type : TimerMapType){
        if self.enableLifecycleTracker{
            let timerActivity = getTimerActivity(pageName, id: id)
            btTimeActivityrMap[id] = timerActivity
            timerActivity.manageTimeFor(type: type)
            if type == .disapear{
                btTimeActivityrMap.removeValue(forKey: id)
            }
        }
    }
    
    private func getTimerActivity(_ pageName : String, id : String) -> TimerMapActivity{
        
        if let btTimerActivity = btTimeActivityrMap[id] {
            return btTimerActivity
        }else{
            let timerActivity = TimerMapActivity(pageName: pageName, viewType: self.viewType)
            return timerActivity
        }
    }
    
    private func registerAppForegroundAndBackgroundNotification() {
#if os(iOS)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
#endif
    }
    
    private func stopActiveTimersWhenAppWentToBackground(){
        if self.enableLifecycleTracker{
            for key in  btTimeActivityrMap.keys{
                if let timerActivity = btTimeActivityrMap[key] {
                    let page = timerActivity.getPageName()
                    startTimerPages[key] = page
                    viewingEnd(key, page)
                }
            }
            
            self.logger?.info("Stop active timer when app went to background")
        }
    }

    private func startInactiveTimersWhenAppCameToForeground(){
        if self.enableLifecycleTracker{
            for key in  startTimerPages.keys{
                if let page = startTimerPages[key] {
                    viewStart(key, page)
                }
            }
            startTimerPages.removeAll()
            
            self.logger?.info("Start active timer when app come to foreground")
        }
    }
    
    @objc private func appMovedToBackground() {
        BTTScreenLifecycleTracker.shared.stopActiveTimersWhenAppWentToBackground()
    }
    
    @objc private func appMovedToForeground() {
        BTTScreenLifecycleTracker.shared.startInactiveTimersWhenAppCameToForeground()
    }
}

enum TimerMapType {
  case load, finish, view, disapear
}

class TimerMapActivity {
    
    private let timer : BTTimer
    private let pageName : String
    private let viewType : ViewType
    private var loadTime : TimeInterval?
    private var viewTime : TimeInterval?
    private var disapearTime : TimeInterval?
    
    init(pageName: String, viewType : ViewType) {
        self.pageName = pageName
        self.viewType = viewType
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
            if loadTime == nil{
                loadTime = timeInterval
            }
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
                maxMainThreadUsage: timer.performanceReport?.maxMainThreadTask.milliseconds ?? 0,viewType: self.viewType)
        }
        BlueTriangle.endTimer(timer)
    }
    
    func getPageName()->String{
        return pageName
    }
    
    private var timeInterval : TimeInterval{
        Date().timeIntervalSince1970
    }
}


