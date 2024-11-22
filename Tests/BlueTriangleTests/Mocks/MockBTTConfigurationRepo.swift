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
                                                    dateSaved: Date().timeIntervalSince1970.milliseconds)
        store[key] = newConfig
    }
    
    func synchronize() {
        if let value = store[key]?.networkSampleRateSDK {
            let rate = Double(value) / 100.0
            sampleRate = rate
        }
    }
}
