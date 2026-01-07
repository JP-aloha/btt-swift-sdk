//
//  BTTRemoteConfig.swift
//
//
//  Created by Ashok Singh on 05/09/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

class BTTRemoteConfig: Codable, Equatable {
    var networkSampleRateSDK: Double?
    var groupedViewSampleRate: Double?
    var enableRemoteConfigAck: Bool?
    var ignoreScreens : [String]?
    var enableAllTracking: Bool?
    var enableScreenTracking : Bool?
    var enableGrouping: Bool?
    var groupingIdleTime: Double?
    //new
    var enableCrashTracking: Bool?
    var enableANRTracking: Bool?
    var enableMemoryWarning: Bool?
    var enableLaunchTime: Bool?
    var enableWebViewStitching: Bool?
    var enableNetworkStateTracking: Bool?
    var enableGroupingTapDetection: Bool?
    
    
    init(networkSampleRateSDK: Double?,
         groupedViewSampleRate: Double?,
         enableRemoteConfigAck : Bool?,
         enableAllTracking : Bool?,
         enableScreenTracking: Bool?,
         enableGrouping : Bool?,
         groupingIdleTime : Double?,
         ignoreScreens : [String]?,
         enableCrashTracking: Bool?,
         enableANRTracking: Bool?,
         enableMemoryWarning: Bool?,
         enableLaunchTime: Bool?,
         enableWebViewStitching: Bool?,
         enableNetworkStateTracking: Bool?,
         enableGroupingTapDetection: Bool?) {
        self.networkSampleRateSDK = networkSampleRateSDK
        self.groupedViewSampleRate = groupedViewSampleRate
        self.enableRemoteConfigAck = enableRemoteConfigAck
        self.ignoreScreens = ignoreScreens
        self.enableAllTracking = enableAllTracking
        self.enableScreenTracking = enableScreenTracking
        self.enableGrouping = enableGrouping
        self.groupingIdleTime = groupingIdleTime
        
        self.enableCrashTracking = enableCrashTracking
        self.enableANRTracking = enableANRTracking
        self.enableMemoryWarning = enableMemoryWarning
        self.enableLaunchTime = enableLaunchTime
        self.enableWebViewStitching = enableWebViewStitching
        self.enableNetworkStateTracking = enableNetworkStateTracking
        self.enableGroupingTapDetection = enableGroupingTapDetection
    }
    
    static func == (lhs: BTTRemoteConfig, rhs: BTTRemoteConfig) -> Bool {
        return lhs.networkSampleRateSDK == rhs.networkSampleRateSDK &&
        lhs.enableRemoteConfigAck == rhs.enableRemoteConfigAck  &&
        lhs.groupedViewSampleRate == rhs.groupedViewSampleRate  &&
        lhs.ignoreScreens == rhs.ignoreScreens &&
        lhs.enableAllTracking == rhs.enableAllTracking &&
        lhs.enableScreenTracking == rhs.enableScreenTracking &&
        lhs.enableGrouping == rhs.enableGrouping &&
        lhs.groupingIdleTime == rhs.groupingIdleTime  &&
        lhs.enableCrashTracking == rhs.enableCrashTracking &&
        lhs.enableANRTracking == rhs.enableANRTracking &&
        lhs.enableMemoryWarning == rhs.enableMemoryWarning &&
        lhs.enableLaunchTime == rhs.enableLaunchTime &&
        lhs.enableWebViewStitching == rhs.enableWebViewStitching &&
        lhs.enableNetworkStateTracking == rhs.enableNetworkStateTracking &&
        lhs.enableGroupingTapDetection == rhs.enableGroupingTapDetection
    }
    
    internal static var defaultConfig: BTTSavedRemoteConfig {
        BTTSavedRemoteConfig(networkSampleRateSDK: BlueTriangle.configuration.networkSampleRate * 100,
                             groupedViewSampleRate: BlueTriangle.configuration.groupedViewSampleRate * 100,
                             enableRemoteConfigAck : false,
                             enableAllTracking: true,
                             enableScreenTracking: BlueTriangle.configuration.enableScreenTracking,
                             enableGrouping: BlueTriangle.configuration.enableGrouping,
                             groupingIdleTime: BlueTriangle.configuration.groupingIdleTime,
                             ignoreScreens: Array(BlueTriangle.configuration.ignoreViewControllers),
                             enableCrashTracking: BlueTriangle.configuration.crashTracking == .nsException,
                             enableANRTracking: BlueTriangle.configuration.ANRMonitoring,
                             enableMemoryWarning: BlueTriangle.configuration.enableMemoryWarning,
                             enableLaunchTime: BlueTriangle.configuration.enableLaunchTime,
                             enableWebViewStitching: BlueTriangle.configuration.enableWebViewStitching,
                             enableNetworkStateTracking: BlueTriangle.configuration.enableTrackingNetworkState,
                             enableGroupingTapDetection: BlueTriangle.configuration.enableGroupingTapDetection,
                             dateSaved: Date().timeIntervalSince1970.milliseconds)
    }
}
