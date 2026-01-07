//
//  MockBTTConfigurationRepo.swift
//  
//
//  Created by Ashok Singh on 10/09/24.
//

import XCTest
@testable import BlueTriangle

class MockBTTConfigurationRepo: ConfigurationRepo {
     
    var store = [String: BTTSavedRemoteConfig]()
    var sampleRate : Double = 0.0
    let key = BlueTriangle.siteID
    
    func get() -> BTTSavedRemoteConfig? {
        return store[key]
    }
    
    func save(_ config: BTTRemoteConfig) {
        let newConfig = BTTSavedRemoteConfig(networkSampleRateSDK: config.networkSampleRateSDK,
                                             groupedViewSampleRate: config.groupedViewSampleRate,
                                             enableRemoteConfigAck: config.enableRemoteConfigAck,
                                             enableAllTracking: config.enableAllTracking,
                                             enableScreenTracking: config.enableScreenTracking,
                                             enableGrouping: config.enableGrouping,
                                             groupingIdleTime: config.groupingIdleTime,
                                             ignoreScreens: config.ignoreScreens,
                                             enableCrashTracking: config.enableCrashTracking,
                                             enableANRTracking: config.enableANRTracking,
                                             enableMemoryWarning: config.enableMemoryWarning,
                                             enableLaunchTime: config.enableLaunchTime,
                                             enableWebViewStitching: config.enableWebViewStitching,
                                             enableNetworkStateTracking: config.enableNetworkStateTracking,
                                             enableGroupingTapDetection: config.enableGroupingTapDetection,
                                             dateSaved: Date().timeIntervalSince1970.milliseconds)
        store[key] = newConfig
    }
    
    func hasChange(_ config: BTTRemoteConfig) -> Bool {
        return true
    }
}
