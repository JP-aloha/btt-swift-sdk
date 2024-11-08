//
//  BTTRemoteConfig.swift
//  
//
//  Created by Ashok Singh on 05/09/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

class BTTRemoteConfig: Codable, Equatable {
    var errorSamplePercent: Int
    var wcdSamplePercent: Int
    var sessionDuration: Int?
    
    init(errorSamplePercent: Int,
         wcdSamplePercent: Int,
         sessionDuration: Int? = nil) {
       
        self.errorSamplePercent = errorSamplePercent
        self.wcdSamplePercent = wcdSamplePercent
        self.sessionDuration = sessionDuration
    }
    
    static func == (lhs: BTTRemoteConfig, rhs: BTTRemoteConfig) -> Bool {
        return lhs.errorSamplePercent == rhs.errorSamplePercent &&
        lhs.wcdSamplePercent == rhs.wcdSamplePercent &&
        lhs.sessionDuration == rhs.sessionDuration
    }
    
    public static var defaultConfig: BTTRemoteConfig {
        BTTRemoteConfig(errorSamplePercent: 0,
                          wcdSamplePercent: Int(BlueTriangle.configuration.networkSampleRate * 100))
    }
}
