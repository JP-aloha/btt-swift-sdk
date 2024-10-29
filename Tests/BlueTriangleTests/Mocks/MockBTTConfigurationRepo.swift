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
    
    func get(_ key: String) -> BTTSavedRemoteConfig? {
        return store[key]
    }
    
    func save(_ config: BTTRemoteConfig, key: String) {
        let newConfig = BTTSavedRemoteConfig(errorSamplePercent: config.errorSamplePercent,
                                                    wcdSamplePercent: config.wcdSamplePercent,
                                                    dateSaved: Date().timeIntervalSince1970.milliseconds)
        store[key] = newConfig
    }
    
    func synchronize(_ key: String) {
        if let value = store[key]?.wcdSamplePercent {
            let rate = Double(value) / 100.0
            sampleRate = rate
        }
    }
}
