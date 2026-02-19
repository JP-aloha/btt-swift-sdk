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

#if canImport(AppEventLogger)
import AppEventLogger
#endif

protocol BTScreenLifecycleTracker{
    func loadStarted(_ id : String, _ name : String, _ title : String)
    func loadFinish(_ id : String, _ name : String,_ title : String)
    func viewStart(_ id : String, _ name : String, _ title : String)
    func viewingEnd(_ id : String, _ name : String, _ title : String)
}

public class BTTScreenLifecycleTracker : BTScreenLifecycleTracker{
    private var btTimeActivityrMap = [String: TimerMapActivity]()
    private var enableLifecycleTracker = false
    private var screenType = ScreenType.UIKit
    private(set) var logger : Logging?
    private var startTimerPages = [String : (name: String, title: String)]()
    private let lock = NSLock()
    
    internal init() {
        registerAppForegroundAndBackgroundNotification()
    }

    func setUpLogger(_ logger : Logging){
        lock.sync {
            self.logger = logger
        }
    }
    
    func setLifecycleTracker(_ enable : Bool){
        lock.sync {
            self.enableLifecycleTracker = enable
        }
    }
    
    func setUpScreenType(_ type : ScreenType){
        lock.sync {
            self.screenType = type
        }
    }
    
    func loadStarted(_ id: String, _ name: String, _ title : String = "") {
        self.manageTimer(name, id: id, type: .load, title: title)
    }
    
    func loadFinish(_ id: String, _ name: String, _ title : String = "") {
        self.manageTimer(name, id: id, type: .finish, title: title)
    }
    
    func viewStart(_ id: String, _ name: String, _ title : String = "") {
        self.manageTimer(name, id: id, type: .view, title: title)
    }
    
    func viewingEnd(_ id: String, _ name: String, _ title : String = "") {
        self.manageTimer(name, id: id, type: .disappear, title: title)
    }
    
    func manageTimer(_ pageName : String, id : String, type : TimerMapType, title : String = ""){
        lock.sync {
            guard self.enableLifecycleTracker else { return }
            let timerActivity = getTimerActivity(pageName, id: id, pageTitle: title)
            btTimeActivityrMap[id] = timerActivity
            timerActivity.manageTimeFor(type: type)
            if type == .disappear{
                btTimeActivityrMap.removeValue(forKey: id)
            }
            else if (type == .load || type == .view){
                SignalHandler.setCurrentPageName(pageName)
                let traficSegment = BlueTriangle.trafficSegmentName == Constants.defaultTraficSegment ? Constants.SCREEN_TRACKING_TRAFFIC_SEGMENT : BlueTriangle.trafficSegmentName
                let pageType = BlueTriangle.pageType == Constants.defaultPageType ? Constants.SCREEN_TRACKING_PAGE_TYPE : BlueTriangle.pageType
                SignalHandler.setTraficSegment(traficSegment)
                SignalHandler.setPageType(pageType)
            }
        }
    }
    
    private func getTimerActivity(_ pageName : String, id : String, pageTitle : String = "") -> TimerMapActivity{
        if let btTimerActivity = btTimeActivityrMap[id] {
            btTimerActivity.setPageName(pageName,title: pageTitle)
            return btTimerActivity
        }else{
            let timerActivity = TimerMapActivity(pageName: pageName, screenType: self.screenType, logger: logger, pageTitle: pageTitle)
            return timerActivity
        }
    }
    
    private func registerAppForegroundAndBackgroundNotification() {
#if os(iOS)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
#endif
    }
    
    private func stopActiveTimersWhenAppWentToBackground() {
        var items: [(key: String, page: String, title: String)] = []
        
        lock.sync {
            guard self.enableLifecycleTracker else { return }

            for (key, activity) in btTimeActivityrMap {
                let page = activity.getPageName()
                let title = activity.getTitleName()
                startTimerPages[key] = (page, title)
                items.append((key: key, page: page, title: title))
            }
        }
        
        for item in items {
            viewingEnd(item.key, item.page, item.title)
        }
        lock.sync {
            btTimeActivityrMap.removeAll()
        }

        logger?.info("Stop active timer when app went to background")
    }

    private func startInactiveTimersWhenAppCameToForeground() {
        var items: [(key: String, page: (name: String, title: String))] = []

        lock.sync {
            guard self.enableLifecycleTracker else { return }
            items = startTimerPages.map { ($0.key, $0.value) }
            startTimerPages.removeAll()
        }

        for (key, page) in items {
            viewStart(key, page.name, page.title)
        }

        logger?.info("Start active timer when app come to foreground")
    }
    
    @objc private func appMovedToBackground() {
        BlueTriangle.screenTracker?.stopActiveTimersWhenAppWentToBackground()
    }
    
    @objc private func appMovedToForeground() {
        BlueTriangle.screenTracker?.startInactiveTimersWhenAppCameToForeground()
    }
    
    func stop(){
#if os(iOS)
        UIViewController.removeSetUp()
        NotificationCenter.default.removeObserver(self)
#endif
    }
}

enum TimerMapType {
  case load, finish, view, disappear
}

class TimerMapActivity {
    
    private let timer : BTTimer
    private let screenType : ScreenType
    private var loadTime : Millisecond?
    private var willViewTime : Millisecond?
    private var viewTime : Millisecond?
    private var disapearTime : Millisecond?
    private var confidenceRate : Int32? = 100
    private var confidenceMsg : String? = ""
    private(set) var logger : Logging?
    private let maxPGTMTime : Millisecond = 20_000
    
    init(pageName: String, screenType : ScreenType, logger : Logging?, pageTitle : String = "") {
        self.screenType = screenType
        self.logger = logger
        
        let trafficSegment = BlueTriangle.trafficSegmentName == Constants.defaultTraficSegment ? Constants.SCREEN_TRACKING_TRAFFIC_SEGMENT : BlueTriangle.trafficSegmentName
        let pageType = BlueTriangle.pageType == Constants.defaultPageType ? Constants.SCREEN_TRACKING_PAGE_TYPE : BlueTriangle.pageType
        
        if BlueTriangle.configuration.enableGrouping {
            BlueTriangle.groupTimer.startGroupIfNeeded(pageTitle.isEmpty ? pageName : pageTitle)
            self.timer = BlueTriangle.startTimer(page:Page(pageName: pageName, pageTitle: pageTitle, pageType: pageType, trafficSegment: trafficSegment), timerType: .custom, isGroupedTimer: true)
        } else {
            self.timer = BlueTriangle.startTimer(page:Page(pageName: pageName, pageType: pageType, trafficSegment: trafficSegment))
        }
        
        self.checkOutEvent(pageName)
    }
    
    func checkOutEvent(_ pageName : String) {
        Task {
            await BlueTriangle.checkoutEvent.onCheckoutEvent(ClassCheckoutEvent(name: pageName))
        }
    }
    
    func setPageName(_ pageName : String, title: String){
        if timer.isGroupTimer {
            self.timer.setPageName(pageName)
            self.timer.setPageTitle(title)
        }
    }
    
    func manageTimeFor(type: TimerMapType) {
        switch type {
        case .load:
            setLoadTime(timeInMillisecond)
        case .finish:
            if loadTime == nil { setLoadTime(timeInMillisecond) }
            setWillViewTime(timeInMillisecond)
        case .view:
            if loadTime == nil { setLoadTime(timeInMillisecond) }
            setViewTime(timeInMillisecond)
        case .disappear:
            evaluateConfidence()
            setDisappearTime(timeInMillisecond)
        }
    }
    
    private func setLoadTime(_ time : Millisecond){
        self.loadTime = time
        self.submitTimerOfType(.load)
        BlueTriangle.groupTimer.refreshGroupName()
    }
    
    private func setWillViewTime(_ time : Millisecond){
        self.willViewTime = time
        BlueTriangle.groupTimer.refreshGroupName()
    }
    
    private func setViewTime(_ time : Millisecond){
        self.viewTime = time
        self.submitTimerOfType(.view)
        BlueTriangle.groupTimer.refreshGroupName()
    }
    
    private func setDisappearTime(_ time : Millisecond){
        self.disapearTime = time
        self.submitTimerOfType(.disappear)
        BlueTriangle.groupTimer.refreshGroupName()
    }
    
    private func evaluateConfidence() {
        switch (loadTime, willViewTime, viewTime) {
        case let (_, willView?, nil):
            self.setViewTime(willView)
            confidenceRate = 50
            confidenceMsg = "viewDidAppear tracking information is missing."
            
        case let (load?, nil, view?):
            let timeGap = view - load
            if timeGap >= maxPGTMTime {
                confidenceRate = 50
                confidenceMsg = "viewDidLoad tracking correct information is missing."
            }else {
                confidenceRate = 100
                confidenceMsg = ""
            }
            
        case  let (load?, willView?, _):
            let timeGap = (willView - load)
            if timeGap >= maxPGTMTime {
                self.loadTime = willView
                confidenceRate = 50
                confidenceMsg = "viewDidLoad tracking correct information are missing."
            } else {
                confidenceRate = 100
                confidenceMsg = ""
            }
            
        case (nil, _, _):
            confidenceRate = 100
            confidenceMsg = ""
            
        default:
            confidenceRate = 0
            confidenceMsg = "Lifecycle tracking information are missing"
        }
    }

    func getPageName()-> String {
        return self.timer.getPageName()
    }
    
    func getTitleName()-> String {
        return self.timer.getPageTitle()
    }
    
    private func submitTimerOfType(_ type : TimerMapType) {
        if isGroupedANDAutoTracked {
            if type == .load {
                BlueTriangle.groupTimer.add(timer: timer)
            }
            if type == .view {
                if let viewTime = viewTime, let loadTime = loadTime {
                    self.updateTrackingTimer(loadTime: loadTime, viewTime: viewTime, disapearTime: timeInMillisecond)
                }
            } else {
                if let viewTime = viewTime, let loadTime = loadTime, let disapearTime = disapearTime {
                    self.updateTrackingTimer(loadTime: loadTime, viewTime: viewTime, disapearTime: disapearTime)
                    if timer.isGroupTimer {
                        timer.end()
                    } else {
                        //Submit timer when switch from non group to group
                        submitTimer()
                    }
                } else if type == .disappear {
                    timer.end()
                }
            }
        } else {
            if type == .disappear {
                submitTimer()
            }
        }
    }
    
    private func submitTimer() {
        if let viewTime = viewTime, let loadTime = loadTime, let disapearTime = disapearTime {
            self.updateTrackingTimer(loadTime: loadTime, viewTime: viewTime, disapearTime: disapearTime)
            BlueTriangle.endTimer(timer)
            let pageInfoMessage = "View tracker timer submited for screen :\(self.timer.getPageName())"
            self.logger?.info(pageInfoMessage)
        } else {
            self.timer.end()
        }
    }

    private func updateTrackingTimer(loadTime: Millisecond, viewTime: Millisecond, disapearTime: Millisecond) {
         //When "pgtm" is zero then fallback mechanism triggered that calculate performence time as screen time automatically. So to avoiding "pgtm" zero value setting default value 15 milliseconds.
         // Default "pgtm" should be minimum 0.01 sec (15 milliseconds). Because timer is not reflecting on dot chat bellow to that interval.
        let calculatedLoadTime = min(max(viewTime - loadTime, Constants.minPgTm), maxPGTMTime)
        let networkReport = timer.networkReport

        timer.pageTimeBuilder = {
            return calculatedLoadTime
        }
        
        let traficSegment = BlueTriangle.trafficSegmentName == Constants.defaultTraficSegment ? Constants.SCREEN_TRACKING_TRAFFIC_SEGMENT : BlueTriangle.trafficSegmentName
        timer.setTrafficSegment(traficSegment)
        timer.nativeAppProperties = NativeAppProperties(
            fullTime: disapearTime - loadTime,
            loadTime: calculatedLoadTime,
            loadStartTime: loadTime,
            loadEndTime: viewTime,
            maxMainThreadUsage: timer.performanceReport?.maxMainThreadTask.milliseconds ?? 0,
            screenType: self.screenType,
            offline: networkReport?.offline ?? 0,
            wifi: networkReport?.wifi ?? 0,
            cellular: networkReport?.cellular ?? 0,
            ethernet: networkReport?.ethernet ?? 0,
            other: networkReport?.other ?? 0,
            confidenceRate: self.confidenceRate,
            confidenceMsg: self.confidenceMsg,
            netState: networkReport?.netState ?? "",
            netStateSource: networkReport?.netSource ?? ""
        )
    }
    
    private var isGroupedANDAutoTracked : Bool {
        BlueTriangle.configuration.enableGrouping
    }
    
    private var timeInMillisecond : Millisecond{
        Date().timeIntervalSince1970.milliseconds
    }
}
