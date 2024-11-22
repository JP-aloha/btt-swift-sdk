//
//  BTTConfigurationRepoTests.swift
//  
//
//  Created by Ashok Singh on 09/09/24.
//

import XCTest
@testable import BlueTriangle

final class BTTConfigurationRepoTests: XCTestCase {
    
    var configurationRepo: MockBTTConfigurationRepo!
    let key = BlueTriangle.siteID
    
    override func setUp() {
        super.setUp()
        configurationRepo = MockBTTConfigurationRepo()
    }
    
    override func tearDown() {
        configurationRepo = nil
        super.tearDown()
    }

    func testSaveConfig() {
        let config = BTTRemoteConfig(networkSampleRateSDK: 5)
        configurationRepo.save(config)
        
        XCTAssertNotNil(configurationRepo.store[key])
        
        let savedConfig = configurationRepo.store[key]
        XCTAssertEqual(savedConfig?.networkSampleRateSDK, 5)
    }
    
    func testGetConfigSuccess() {
        
        let savedConfig = BTTSavedRemoteConfig(networkSampleRateSDK: 5, dateSaved: Date().timeIntervalSince1970.milliseconds)
        configurationRepo.store[key] = savedConfig
        
        let fetchedConfig = configurationRepo.get()
        
        XCTAssertNotNil(fetchedConfig)
        XCTAssertEqual(fetchedConfig?.networkSampleRateSDK, 5)
    }
    
    func testSaveAndRetrieveNilConfig() {
        let retrievedConfig = configurationRepo.get()
        XCTAssertNil(retrievedConfig)
    }
    
    func testSynchronizeUpdatesNetworkSampleRate() {
        // Save the config
        let config = BTTRemoteConfig(networkSampleRateSDK: 5)
        configurationRepo.save(config)
        configurationRepo.synchronize()
        
        if let networkSampleRateSDK = config.networkSampleRateSDK{
            let expectedSampleRate = Double(networkSampleRateSDK) / 100.0
            XCTAssertEqual(configurationRepo.sampleRate, expectedSampleRate, accuracy: 0.001)
        }
    }
}
