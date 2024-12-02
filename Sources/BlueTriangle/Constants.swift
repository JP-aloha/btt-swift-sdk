//
//  Constants.swift
//
//  Created by Mathew Gacy on 10/8/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

enum Constants {
    static let browser = "Native App"
    static let device = "Mobile"
    static let os = "iOS"
    static let globalUserIDKey = "com.bluetriangle.kGlobalUserIDUserDefault"
    static let persistenceDirectory = "com.bluetriangle.sdk"
    static let sdkProductIdentifier = "btt-swift-sdk"
    static let cacheRequestsDirectory = "CacheRequests"
    
    // Settings
    static let minimumSampleInterval: TimeInterval = 1 / 60
    static let sessionTimeoutInMinutes = 30
    static let userSessionTimeoutInDays = 365
    static let maxPayloadAttempts = 3
    
    // Endpoints
    static let capturedRequestEndpoint: URL = "https://d.btttag.com/wcdv02.rcv"
    static let errorEndpoint: URL = "https://d.btttag.com/err.rcv"
    static let timerEndpoint: URL = "https://d.btttag.com/analytics.rcv"
    static let connfigEndPoint: URL = "https://d.btttag.com/config.php"

    // Crash Tracking
    static let crashID = "iOS Crash"
    static let crashReportFilename = "com.bluetriangle.crash"
    static let crashReportLineSeparator = "~~"
    static let excludedValue = "20"
    static let startupDelay: TimeInterval = 10
    static let minPgTm : Millisecond = 15

    // Custom Metrics
    static let metricsCharacterLimit = 1024
    static let metricsSizeLimit = 3_000_000

    // Logging
    static let loggingSubsystem = "com.bluetriangle.sdk"
    static let loggingCategory = "tracker"
    
    static let COLD_LAUNCH_PAGE_NAME = "ColdLaunchTime"
    static let HOT_LAUNCH_PAGE_NAME = "HotLaunchTime"
    static let LAUNCH_TIME_PAGE_GROUP = "LaunchTime"
    static let LAUNCH_TIME_TRAFFIC_SEGMENT = "LaunchTime"
    static let SCREEN_TRACKING_TRAFFIC_SEGMENT = "ScreenTracker"
    
    //Dynamic Config
    static let FULL_SAMPLE_RATE_ARGUMENT  = "-FullSampleRate"
    static let NEW_SESSION_ON_LAUNCH_ARGUMENT  = "-NewSessionOnLaunch"

}
