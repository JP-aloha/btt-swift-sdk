//
//  BTTSavedRemoteConfig.swift
//
//
//  Created by Ashok Singh on 05/09/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//


import Foundation

class BTTSavedRemoteConfig: BTTRemoteConfig {
    var dateSaved: Millisecond
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
         checkoutTimeValue : Int?,
         dateSaved: Millisecond) {
        self.dateSaved = dateSaved
        super.init(networkSampleRateSDK: networkSampleRateSDK,
                   enableRemoteConfigAck: enableRemoteConfigAck,
                   enableAllTracking: enableAllTracking,
                   enableScreenTracking: enableScreenTracking,
                   enableGrouping: enableGrouping,
                   groupingIdleTime: groupingIdleTime,
                   ignoreScreens: ignoreScreens,
                   enableCrashTracking: enableCrashTracking,
                   enableANRTracking: enableANRTracking,
                   enableMemoryWarning: enableMemoryWarning,
                   enableLaunchTime: enableLaunchTime,
                   enableWebViewStitching: enableWebViewStitching,
                   enableNetworkStateTracking: enableNetworkStateTracking,
                   enableGroupingTapDetection: enableGroupingTapDetection,
                   checkoutTrackingEnabled: checkoutTrackingEnabled,
                   checkoutClassName: checkoutClassName,
                   checkoutURL: checkoutURL,
                   checkoutAmount: checkoutAmount,
                   checkoutCartCount: checkoutCartCount,
                   checkoutCartCountCheckout: checkoutCartCountCheckout,
                   checkoutOrderNumber: checkoutOrderNumber,
                   checkoutTimeValue: checkoutTimeValue
        )
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dateSaved = try container.decode(Millisecond.self, forKey: .dateSaved)
        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dateSaved, forKey: .dateSaved)
        try super.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case dateSaved
    }
}
