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
    var enableRemoteConfigAck: Bool?
    var ignoreScreens : [String]?
    var enableAllTracking: Bool?
    var enableScreenTracking : Bool?
    var enableGrouping: Bool?
    var groupingIdleTime: Double?
    var enableCrashTracking: Bool?
    var enableANRTracking: Bool?
    var enableMemoryWarning: Bool?
    var enableLaunchTime: Bool?
    var enableWebViewStitching: Bool?
    var enableNetworkStateTracking: Bool?
    var enableGroupingTapDetection: Bool?
    var checkoutTrackingEnabled : Bool?
    var checkoutClassName : [String]?
    var checkoutURL : String?
    var checkoutAmount : Double?
    var checkoutCartCount : Int?
    var checkoutCartCountCheckout: Int?
    var checkoutOrderNumber : String?
    var checkoutTimeValue : Int?
    
    
    init(networkSampleRateSDK: Double?,
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
         enableGroupingTapDetection: Bool?,
         checkoutTrackingEnabled : Bool?,
         checkoutClassName : [String]?,
         checkoutURL : String?,
         checkoutAmount : Double?,
         checkoutCartCount : Int?,
         checkoutCartCountCheckout: Int?,
         checkoutOrderNumber : String?,
         checkoutTimeValue : Int?) {
        self.networkSampleRateSDK = networkSampleRateSDK
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
        
        self.checkoutTrackingEnabled = checkoutTrackingEnabled
        self.checkoutClassName = checkoutClassName
        self.checkoutURL = checkoutURL
        self.checkoutAmount = checkoutAmount
        self.checkoutCartCount = checkoutCartCount
        self.checkoutCartCountCheckout = checkoutCartCountCheckout
        self.checkoutOrderNumber = checkoutOrderNumber
        self.checkoutTimeValue = checkoutTimeValue
    }
    
    static func == (lhs: BTTRemoteConfig, rhs: BTTRemoteConfig) -> Bool {
        return lhs.networkSampleRateSDK == rhs.networkSampleRateSDK &&
        lhs.enableRemoteConfigAck == rhs.enableRemoteConfigAck  &&
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
        lhs.enableGroupingTapDetection == rhs.enableGroupingTapDetection &&

        lhs.checkoutTrackingEnabled == rhs.checkoutTrackingEnabled &&
        lhs.checkoutClassName == rhs.checkoutClassName &&
        lhs.checkoutURL == rhs.checkoutURL &&
        lhs.checkoutAmount == rhs.checkoutAmount &&
        lhs.checkoutCartCount == rhs.checkoutCartCount &&
        lhs.checkoutCartCountCheckout == rhs.checkoutCartCountCheckout &&
        lhs.checkoutOrderNumber == rhs.checkoutOrderNumber &&
        lhs.checkoutTimeValue == rhs.checkoutTimeValue
    }
    
    internal static var defaultConfig: BTTSavedRemoteConfig {
        BTTSavedRemoteConfig(networkSampleRateSDK: BlueTriangle.configuration.networkSampleRate * 100,
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
                             checkoutTrackingEnabled: BlueTriangle.configuration.checkoutTrackingEnabled,
                             checkoutClassName: BlueTriangle.configuration.checkoutClassName,
                             checkoutURL: BlueTriangle.configuration.checkoutURL,
                             checkoutAmount: BlueTriangle.configuration.checkoutAmount,
                             checkoutCartCount: BlueTriangle.configuration.checkoutCartCount,
                             checkoutCartCountCheckout: BlueTriangle.configuration.checkoutCartCountCheckout,
                             checkoutOrderNumber: BlueTriangle.configuration.checkoutOrderNumber,
                             checkoutTimeValue: BlueTriangle.configuration.checkoutTimeValue,
                             dateSaved: Date().timeIntervalSince1970.milliseconds)
    }
}
