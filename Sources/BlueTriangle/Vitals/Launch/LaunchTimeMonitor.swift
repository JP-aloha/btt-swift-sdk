//
//  LaunchTimeMonitor.swift
//
//
//  Created by Ashok Singh on 06/05/24.
//



import Foundation
import Combine
#if canImport(AppEventLogger)
import AppEventLogger
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

enum LaunchEvent {
    case Cold(Date, TimeInterval, Int32)
    case Hot(Date, TimeInterval, Int32)
}

enum SystemEvent {
    case didFinishLaunch(Date)
    case didEnterForeground(Date)
    case didBecomeActive(Date)
}

class LaunchTimeMonitor : ObservableObject {
    
    internal var launchEventPublisher = CurrentValueSubject<LaunchEvent?, Never>(nil)
    private let launchTimeThreshold: TimeInterval = 120 // 2 minutes
    private let serialQueue = DispatchQueue(label: "com.launchtimemonitor.queue")
    private let logger: Logging
    private var systemEventLog = [SystemEvent]()
    private var launchObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?
    private var activeObserver: NSObjectProtocol?
    private var sceneActiveObserver: NSObjectProtocol?
    private var didReportCold = false
    private var didReportHot = false
    
    init(logger: Logging) {
        self.logger  = logger
    }
    
    func start() {
        self.registerNotifications()
        self.restoreNotificationLogs()
    }
    
    func stop() {
        self.removeNotifications()
    }
    
    private func restoreNotificationLogs() {
        let appNotificationLogs = AppNotificationLogger.getNotifications()
        appNotificationLogs.forEach { notification in
            if let notificationLog = notification as? NotificationLog {
                self.processNotification(notificationLog.notification, date: notificationLog.time)
            }
        }
        
        //fallback
        serialQueue.async {
            if appNotificationLogs.count > 0 && !self.didReportCold && !self.didReportHot {
                self.notifyLaunchTime()
            }
        }
        
        AppNotificationLogger.removeObserver()
    }
    
    /// Must be called only on `serialQueue`
    private func reset() {
        self.systemEventLog.removeAll()
    }
}

extension LaunchTimeMonitor {
    
    private func processNotification(_ notification: Notification, date : Date) {
#if os(iOS)
        if notification.name == UIApplication.didFinishLaunchingNotification {
            serialQueue.async {
                self.systemEventLog.append(SystemEvent.didFinishLaunch(date))
            }
        } else if notification.name == UIApplication.willEnterForegroundNotification {
            serialQueue.async {
                self.didReportHot = false
                self.systemEventLog.append(SystemEvent.didEnterForeground(date))
            }
        } else if notification.name == UIApplication.didBecomeActiveNotification {
            serialQueue.async {
                self.systemEventLog.append(SystemEvent.didBecomeActive(date))
                self.notifyLaunchTime(date)
            }
        }
#endif
    }
    
    private func registerNotifications() {
#if os(iOS)
        launchObserver = NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            self.processNotification(notification, date: Date())
        }
        foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            self.processNotification(notification, date: Date())
        }
        activeObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            self.processNotification(notification, date: Date())
        }
        //fall back if missed hot or cold launch
        sceneActiveObserver = NotificationCenter.default.addObserver(forName: UIScene.didActivateNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else { return }
            self.serialQueue.async {
                guard !self.didReportHot else {
                    return
                }
                let activationDate = Date()
                self.systemEventLog.append(.didBecomeActive(activationDate))
                self.notifyLaunchTime(activationDate)
            }
        }
        
        logger.info("Launch time monitor started listining to system event")
#endif
    }
    
    private func removeNotifications() {
#if os(iOS)
        if let observer = launchObserver {
             NotificationCenter.default.removeObserver(observer)
            launchObserver = nil
        }
        if let observer = foregroundObserver {
             NotificationCenter.default.removeObserver(observer)
            foregroundObserver = nil
        }
        if let observer = activeObserver {
             NotificationCenter.default.removeObserver(observer)
            activeObserver = nil
        }
        if let observer = sceneActiveObserver {
             NotificationCenter.default.removeObserver(observer)
            sceneActiveObserver = nil
        }
        
        logger.info("Launch time monitor removed listining to system event")
#endif
    }
    
    private func notifyHotLaunch(_ foregroundEvent: SystemEvent, _ activeTime: Date) {
        if case .didEnterForeground(let startTime) = foregroundEvent {
            let duration = activeTime.timeIntervalSince(startTime)
            launchEventPublisher.send(.Hot(startTime, duration, 100))
            logger.info("Notify hot launch at \(startTime)")
        }
    }
    
    private func notifyColdLaunch(_ finishLaunchEvent: SystemEvent, _ activeTime: Date) {
        if case .didFinishLaunch(let startTime) = finishLaunchEvent {
            
            let processStart  = processStartTime()
            let processStartTime = Date(timeIntervalSince1970: processStart)
            let processAge = activeTime.timeIntervalSince(processStartTime)
            // If the threshold exceeds 2 minutes (e.g., due to background fetch processing),
            // the launch is classified as a hot launch.
            if processAge > launchTimeThreshold {
                let duration = activeTime.timeIntervalSince(startTime)
                launchEventPublisher.send(.Hot(startTime, duration, 70))
            } else {
                let duration = activeTime.timeIntervalSince(processStartTime)
                launchEventPublisher.send(.Cold(processStartTime, duration, 100))
            }
            logger.info("Notify cold launch at \(startTime)")
        }
    }
    
    private func flushLaunchEvents(_ activeTime: Date) {
        let events = systemEventLog
        let finishLaunchEvent = events.first { if case .didFinishLaunch = $0 { true } else { false } }
        let foregroundEvent = events.last { if case .didEnterForeground = $0 { true } else { false } }
        
        if let finishLaunchEvent, !didReportCold {
            didReportCold = true
            notifyColdLaunch(finishLaunchEvent, activeTime)
        } else if let foregroundEvent , !didReportHot {
            didReportHot = true
            notifyHotLaunch(foregroundEvent, activeTime)
        }
        
        reset()
    }
    
    /// Must be called only on `serialQueue`
    private func notifyLaunchTime(_ activeTime: Date = Date()) {
        flushLaunchEvents(activeTime)
    }

    private func processStartTime() -> Double {
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        sysctl(&mib, u_int(mib.count), &kinfo, &size, nil, 0)
        let start_time = kinfo.kp_proc.p_starttime
        let processTime = Double(start_time.tv_sec) + Double(start_time.tv_usec) / 1e6
        return processTime
    }
}
