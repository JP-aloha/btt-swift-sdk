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
    var isSDKEnabled: Bool?
    
    init(networkSampleRateSDK: Int?,
         enableRemoteConfigAck : Bool?,
         isSDKEnabled : Bool?,
         ignoreScreens : [String]?) {
        self.networkSampleRateSDK = networkSampleRateSDK
        self.enableRemoteConfigAck = enableRemoteConfigAck
        self.ignoreScreens = ignoreScreens
        self.isSDKEnabled = isSDKEnabled
    }
    
    static func == (lhs: BTTRemoteConfig, rhs: BTTRemoteConfig) -> Bool {
        return lhs.networkSampleRateSDK == rhs.networkSampleRateSDK &&
        lhs.enableRemoteConfigAck == rhs.enableRemoteConfigAck  &&
        lhs.ignoreScreens == rhs.ignoreScreens &&
        lhs.isSDKEnabled == rhs.isSDKEnabled
    }
    
    public static var defaultConfig: BTTSavedRemoteConfig {
        BTTSavedRemoteConfig(networkSampleRateSDK: Int(BlueTriangle.configuration.networkSampleRate * 100),
                             enableRemoteConfigAck : false, 
                             isSDKEnabled: true,
                             ignoreScreens: Array(BlueTriangle.configuration.ignoreViewControllers),
                             dateSaved: Date().timeIntervalSince1970.milliseconds)
    }
}
