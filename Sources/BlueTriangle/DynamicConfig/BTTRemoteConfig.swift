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
    
    init(networkSampleRateSDK: Int?) {
        self.networkSampleRateSDK = networkSampleRateSDK
    }
    
    static func == (lhs: BTTRemoteConfig, rhs: BTTRemoteConfig) -> Bool {
        return lhs.networkSampleRateSDK == rhs.networkSampleRateSDK
    }
    
    public static var defaultConfig: BTTRemoteConfig {
        BTTRemoteConfig(networkSampleRateSDK: Int(BlueTriangle.configuration.networkSampleRate * 100))
    }
}
