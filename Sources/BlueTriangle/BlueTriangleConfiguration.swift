//
//  BlueTriangleConfiguration.swift
//
//  Created by Mathew Gacy on 9/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

/// Configuration object for the Blue Triangle SDK.
final public class BlueTriangleConfiguration: NSObject {
    private var customCampaign: String?
    private var customGlobalUserID: Identifier?
    private var customSessionID: Identifier?

    /// Blue Triangle Technologies-assigned site ID.
    @objc public var siteID: String = ""

    /// Session ID.
    @objc public var sessionID: Identifier {
        get {
            Identifier.random()
        }
        set {
            customSessionID = newValue
        }
    }

    /// Global User ID.
    @objc public var globalUserID: Identifier {
        get {
            var id = Identifier(UserDefaults.standard.integer(forKey: Constants.globalUserIDKey))
            if id == 0 {
                id = Identifier.random()
                UserDefaults.standard.set(id, forKey: Constants.globalUserIDKey)
            }
            return id
        }
        set {
            customGlobalUserID = newValue
        }
    }

    /// Boolean value indicating whether user is a returning visitor.
    @objc public var isReturningVisitor: Bool = false

    /// A/B testing identifier.
    @objc public var abTestID: String = "Default"

    /// Legacy campaign name.
    @available(*, deprecated, message: "Use `campaignName` instead.")
    @objc public var campaign: String? = "" {
        didSet { customCampaign = campaign }
    }

    /// Campaign medium.
    @objc public var campaignMedium: String = ""

    /// Campaign name.
    @objc public var campaignName: String = ""

    /// Campaign source.
    @objc public var campaignSource: String = ""

    /// Data center.
    @objc public var dataCenter: String = "Default"

    /// Traffic segment.
    @objc public var trafficSegmentName: String = ""

    /// Crash tracking behavior.
    @objc public var crashTracking: CrashTracking = .none

    /// Controls the frequency at which app performance is sampled.
    ///
    /// The smallest allowed interval is one measurement every 1/60 of a second.
    @objc public var performanceMonitorSampleRate: TimeInterval = 1
    
    /// Boolean indicating whether performance monitoring is enabled.
    @objc public var isPerformanceMonitorEnabled: Bool = false

    /// Percentage of sessions for which network calls will be captured. A value of `0.05`
    /// means that 5% of sessions will be tracked.
    @objc public var networkSampleRate: Double = 0.05
    
    /// Offline or Failure request storage expiry period by default it is 2 day i.e 2 * 24 * 60 * 60  second
    /// Interval unit should be in Millisecond
    @objc public var cacheExpiryDuration: Millisecond = 2 * 24 * 60 * 60 * 1000
    
    /// Offline or Failure request storage memory limit by default it is 30 Mb i.e 30 * 1024 * 1024 byte
    /// Memory unit should be in Bytes
    @objc public var cacheMemoryLimit: UInt = 30 * 1024 * 1024

    /// When enabled tasks running on main thread are monitored for there run duration time.
    ///
    /// Any task on main thread taking longer (more then 2-3 seconds) will result unresponsive app during that period.
    /// This monitor provides two valuable measurements related main thread usage.
    ///     1. Max Main thread Usage: Each BTTimer will get maximum main thread usage during this BTTimer. How many seconds the longest task on main thread took during every BTTimer.
    ///     2. ANR Warning : If any single task taking more then ``ANRWarningTimeInterval`` "ANRWarningTimeInterval" seconds a warning raised internally and this error reported to Blue Triangle portal.
    /// Default is false
    @objc public var ANRMonitoring: Bool = false
    
    ///ANR stack trace helps to identify ANR location
    ///If its value is true, it send stack trace with ANR warning
    /// Default is false
    @objc public var ANRStackTrace: Bool = false
    
    /// Time interval for ANR Warning see ``ANRMonitoring`` "ANRMonitoring", default to 5 seconds, minimum is 3 sec, if set less then minimum allowed set value is ignored and used minimum interval.
    @objc public var ANRWarningTimeInterval: TimeInterval = 5
    
    /// Boolean indicating whether debug logging is enabled.
    @objc public var enableDebugLogging: Bool = false
    
    /// Boolean indicating whether screen tracking is enabled.
    /// To track alll UIKit screen autometically, It should be enabled
    /// To track swiftUI screen, It should be enabled
    /// You can mannually track view by enabling that
    /// When this is off, Non of above would  get  track
    @objc public var enableScreenTracking: Bool = false
    
    /// This is a  Set of ViewControllers  which developer does not want to track or want to ignore their track. This property can only ignore that screen, Which is being tracked autometically. And It can not ignore , Which is being tracked  manually.
    /// Set an array of view controlles which user want to ignore
    @objc public  var ignoreViewControllers: Set<String> = Set<String>()
    
    /// Track the network state during Timer Network State and Errors. State Includes wifi, cellular, ethernet and offline.
    /// Default Value is false
    @objc public var enableTrackingNetworkState: Bool = false
    
    /// Boolean indicating whether memory warning is enabled.
    @objc public var enableMemoryWarning: Bool = false

    var timerConfiguration: BTTimer.Configuration = .live

    var internalTimerConfiguration: InternalTimer.Configuration = .live

    var uploaderConfiguration: Uploader.Configuration = .live

    var capturedRequestCollectorConfiguration: CapturedRequestCollector.Configuration = .live

    var requestBuilder: TimerRequestBuilder = .live

    var performanceMonitorBuilder: PerformanceMonitorBuilder = .live
}

// MARK: - Supporting Types
extension BlueTriangleConfiguration {

    @objc
    public enum CrashTracking: Int {
        /// Disable crash tracking.
        case none
        /// Report NSExceptions.
        case nsException

        var configuration: CrashReportConfiguration? {
            switch self {
            case .none: return nil
            case .nsException: return .nsException
            }
        }
    }

    func makeSession() -> Session {
        Session(siteID: siteID,
                globalUserID: customGlobalUserID ?? globalUserID,
                sessionID: customSessionID ?? sessionID,
                isReturningVisitor: isReturningVisitor,
                abTestID: abTestID,
                campaign: customCampaign,
                campaignMedium: campaignMedium,
                campaignName: campaignName,
                campaignSource: campaignSource,
                dataCenter: dataCenter,
                trafficSegmentName: trafficSegmentName
        )
    }

    func makeLogger () -> Logging {
        var logger = BTLogger.live
        logger.enableDebug = enableDebugLogging
        return logger
    }

    func makePerformanceMonitorFactory() -> (() -> PerformanceMonitoring)? {
        
        if isPerformanceMonitorEnabled{
            return performanceMonitorBuilder.builder(performanceMonitorSampleRate)
        }else{
            return nil
        }
    }
}
