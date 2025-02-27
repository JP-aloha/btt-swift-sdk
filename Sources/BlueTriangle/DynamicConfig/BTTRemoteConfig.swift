//
//  BTTRemoteConfig.swift
//
//
//  Created by Ashok Singh on 05/09/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

class BTTRemoteConfig: Codable, Equatable {
    var networkSampleRateSDK: Int?
    var enableRemoteConfigAck: Bool?
    var ignoreScreens : [String]?
    var enableAllTracking: Bool?
    var clarityProjectID : String?
    var clarityEnabled : Bool?
    
    init(networkSampleRateSDK: Int?,
         enableRemoteConfigAck : Bool?,
         enableAllTracking : Bool?,
         ignoreScreens : [String]?,
         clarityProjectID : String?,
         clarityEnabled : Bool?) {
        self.networkSampleRateSDK = networkSampleRateSDK
        self.enableRemoteConfigAck = enableRemoteConfigAck
        self.ignoreScreens = ignoreScreens
        self.enableAllTracking = enableAllTracking
        self.clarityProjectID = clarityProjectID
        self.clarityEnabled = clarityEnabled
    }
    
    static func == (lhs: BTTRemoteConfig, rhs: BTTRemoteConfig) -> Bool {
        return lhs.networkSampleRateSDK == rhs.networkSampleRateSDK &&
        lhs.enableRemoteConfigAck == rhs.enableRemoteConfigAck  &&
        lhs.ignoreScreens == rhs.ignoreScreens &&
        lhs.enableAllTracking == rhs.enableAllTracking &&
        lhs.clarityProjectID == rhs.clarityProjectID
    }
    
    internal static var defaultConfig: BTTSavedRemoteConfig {
        BTTSavedRemoteConfig(networkSampleRateSDK: Int(BlueTriangle.configuration.networkSampleRate * 100),
                             enableRemoteConfigAck : false, 
                             enableAllTracking: true, 
                             clarityProjectID: nil, 
                             clarityEnabled: false,
                             ignoreScreens: Array(BlueTriangle.configuration.ignoreViewControllers),
                             dateSaved: Date().timeIntervalSince1970.milliseconds)
    }
}
