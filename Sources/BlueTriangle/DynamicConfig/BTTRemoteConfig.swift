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
    
    init(networkSampleRateSDK: Int?, enableRemoteConfigAck : Bool?) {
        self.networkSampleRateSDK = networkSampleRateSDK
        self.enableRemoteConfigAck = enableRemoteConfigAck
    }
    
    static func == (lhs: BTTRemoteConfig, rhs: BTTRemoteConfig) -> Bool {
        return lhs.networkSampleRateSDK == rhs.networkSampleRateSDK && lhs.enableRemoteConfigAck == rhs.enableRemoteConfigAck
    }
    
    public static var defaultConfig: BTTSavedRemoteConfig {
        BTTSavedRemoteConfig(networkSampleRateSDK: Int(BlueTriangle.configuration.networkSampleRate * 100),
                                             enableRemoteConfigAck : false,
                                             dateSaved: Date().timeIntervalSince1970.milliseconds)
    }
}
