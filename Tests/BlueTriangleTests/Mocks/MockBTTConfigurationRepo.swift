//
//  MockBTTConfigurationRepo.swift
//  
//
//  Created by Ashok Singh on 10/09/24.
//

import XCTest
@testable import BlueTriangle

class MockBTTConfigurationRepo: ConfigurationRepo {
    
    var savedConfig: BTTSavedRemoteConfig?
    
    func get() -> BTTSavedRemoteConfig? {
        return savedConfig
    }
    
    func save(_ config: BTTRemoteConfig) {
        let newConfig = BTTSavedRemoteConfig(errorSamplePercent: config.errorSamplePercent,
                                             wcdSamplePercent: config.wcdSamplePercent,
                                             dateSaved: Date().timeIntervalSince1970.milliseconds)
        savedConfig = newConfig
    }
    
    func clear() {
        savedConfig = nil
    }
}
