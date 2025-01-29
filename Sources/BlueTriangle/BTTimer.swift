//
//  BTTimer.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

/// An object that measures the duration of a user interaction.
final public class BTTimer: NSObject {
    /// Describes the timer type.
    @objc
    public enum TimerType: Int {
        /// A timer used to measure primary user interactions and identify captured network requests.
        case main
        /// A timer used to measure additional interactions.
        case custom
    }

    /// Describes the state of a timer.
    @objc
    public enum State: Int {
        /// Timer has not yet been started.
        case initial
        /// Timer has been started.
        case started
        /// Timer has been marked interactive.
        case interactive
        /// Timer has been ended.
        case ended
    }

    private enum Action {
        case start
        case markInteractive
        case end
    }

    private let lock = NSLock()
    private let logger: Logging
    private let timeIntervalProvider: () -> TimeInterval
    private let onStart: (TimerType, Page, TimeInterval) -> Void
    private let performanceMonitor: PerformanceMonitoring?
    private var networkAccumulator : BTTimerNetStateAccumulatorProtocol?
    private var nativeAppProp : NativeAppProperties?

    /// The type of the timer.
    @objc public let type: TimerType

    /// An object describing the user interaction measured by the timer.
    @objc public var page: Page
    
    /// Traffic segment.
    @objc public var trafficSegmentName: String?

    /// The state of the timer.
    @objc public private(set) var state: State = .initial

    /// The epoch time interval at which the timer was started.
    ///
    /// The default value is `0.0`.
    @objc public private(set) var startTime: TimeInterval = 0.0

    /// The epoch time interval at which the timer was marked interactive.
    ///
    /// The default value is `0.0`.
    @objc public private(set) var interactiveTime: TimeInterval = 0.0
    
    /// The epoch time interval at which the timer was ended.
    ///
    /// The default value is `0.0`.
    @objc public private(set) var endTime: TimeInterval = 0.0
    @objc public var hasEnded: Bool {
        switch state {
        case .ended: return true
        default: return false
        }
    }
    
    let enableAllTracking = BlueTriangle.enableAllTracking

    var pageTimeInterval: PageTimeInterval {
        PageTimeInterval(
            startTime: startTime.milliseconds,
            interactiveTime: interactiveTime.milliseconds,
            pageTime: pageTimeBuilder())
    }
    
    lazy var pageTimeBuilder: () -> Millisecond = {
        self.endTime.milliseconds - self.startTime.milliseconds
    }
    
    var nativeAppProperties: NativeAppProperties{
        get{
            guard let nativeAppProp = nativeAppProp else{
                return NativeAppProperties(
                    fullTime: 0,
                    loadTime: 0,
                    maxMainThreadUsage: performanceReport?.maxMainThreadTask.milliseconds ?? 0,
                    viewType: nil,
                    offline: networkReport?.offline ?? 0,
                    wifi: networkReport?.wifi ?? 0,
                    cellular: networkReport?.cellular ?? 0,
                    ethernet: networkReport?.ethernet ?? 0,
                    other: networkReport?.other ?? 0,
                    netState: networkReport?.netState ?? "",
                    netStateSource: networkReport?.netSource ?? "")
            }
            
            return nativeAppProp
        }
        set(newValue){
            nativeAppProp = newValue
        }
    }

    var performanceReport: PerformanceReport? {
        performanceMonitor?.makeReport()
    }
    
    var networkReport: NetworkReport? {
        return networkAccumulator?.makeReport()
    }

    init(page: Page,
         type: TimerType = .main,
         logger: Logging,
         intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 },
         onStart: @escaping (TimerType, Page, TimeInterval) -> Void = { _, _, _ in },
         performanceMonitor: PerformanceMonitoring? = nil) {
        self.page = page
        self.type = type
        self.logger = logger
        self.timeIntervalProvider = intervalProvider
        self.onStart = onStart
        self.performanceMonitor = performanceMonitor
    }

    /// Start the timer if not already started.
    ///
    /// If already started, will log an error.
    @objc
    public func start() {
        guard enableAllTracking else{
            return
        }
        
        BlueTriangle.addActiveTimer(self)
        handle(.start)
        self.startNetState()
    }

    /// Mark the timer interactive at current time if the timer has been started and not
    /// already marked interactive.
    ///
    /// If the timer has not been started yet or has already been marked interactive,
    /// calling this method will log an error.
    @objc
    public func markInteractive() {
        handle(.markInteractive)
    }

    /// End the timer.
    @objc
    public func end() {
        
        guard enableAllTracking else{
            return
        }
        
        self.stopNetState()
        
        if let pm = performanceMonitor{
            let pageName = self.page.pageName
            let page = pm.debugDescription.replacingOccurrences(of: "PAGE NAME", with: pageName)
            logger.info(page)
        }
        
        BlueTriangle.removeActiveTimer(self)
        handle(.end)
    }

    private func handle(_ action: Action) {
        lock.sync {
            switch (state, action) {
            case (.initial, .start):
                startTime = timeIntervalProvider()
                performanceMonitor?.start()
                state = .started
                onStart(type, page, startTime)
            case (.started, .markInteractive):
                interactiveTime = timeIntervalProvider()
                state = .interactive
            case (.started, .end), (.interactive, .end):
                endTime = timeIntervalProvider()
                performanceMonitor?.end()
                state = .ended
            case (.initial, .markInteractive):
                logger.error("Interactive time cannot be set until timer is started.")
            case (.initial, .end):
                logger.error("Cannot end timer before it is started.")
            case (.started, .start):
                logger.error("Start time already set.")
            case (.interactive, .markInteractive):
                logger.error("Interactive time already set.")
            case (.ended, .start), (.ended, .markInteractive), (.ended, .end):
                return
            default:
                logger.error("Invalid transition.")
            }
        }
    }
}

extension BTTimer{
    func startNetState(){
        if let monitor = BlueTriangle.networkStateMonitor{
            self.networkAccumulator = BTTimerNetStateAccumulator(monitor)
            self.networkAccumulator?.start()
        }
    }
    
    func stopNetState(){
        self.networkAccumulator?.stop()
    }
}

// MARK: - Supporting Types
extension BTTimer {
    struct Configuration {
        let timeIntervalProvider: () -> TimeInterval

        func makeTimerFactory(
            logger: Logging,
            onStart: @escaping (TimerType, Page, TimeInterval) -> Void = BlueTriangle.timerDidStart(_:page:startTime:),
            performanceMonitorFactory: (() -> PerformanceMonitoring)? = nil
        ) -> (Page, BTTimer.TimerType) -> BTTimer {
            { page, timerType in
                BTTimer(page: page,
                        type: timerType,
                        logger: logger,
                        intervalProvider: timeIntervalProvider,
                        onStart: onStart,
                        performanceMonitor: performanceMonitorFactory?())
            }
        }

        static let live = Self(
            timeIntervalProvider: { Date().timeIntervalSince1970 }
        )
    }
}
