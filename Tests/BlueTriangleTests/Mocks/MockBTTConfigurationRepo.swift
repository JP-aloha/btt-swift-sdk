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
    
    func get(_ key: String) -> BTTSavedRemoteConfig? {
        return store[key]
    }
    
    func save(_ config: BTTRemoteConfig, key: String) {
        let newConfig = BTTSavedRemoteConfig(errorSamplePercent: config.errorSamplePercent,
                                                    wcdSamplePercent: config.wcdSamplePercent,
                                                    dateSaved: Date().timeIntervalSince1970.milliseconds)
        store[key] = newConfig
    }
}
