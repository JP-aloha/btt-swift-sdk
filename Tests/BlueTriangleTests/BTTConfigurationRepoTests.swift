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
    
    override func setUp() {
        super.setUp()
        configurationRepo = MockBTTConfigurationRepo()
    }
    
    override func tearDown() {
        configurationRepo = nil
        super.tearDown()
    }
    
    func testSaveConfig() {
        let config = BTTRemoteConfig(errorSamplePercent: 10, wcdSamplePercent: 5)
        let key = "testConfig"
        configurationRepo.save(config, key: key)
        
        XCTAssertNotNil(configurationRepo.store[key])
        
        let savedConfig = configurationRepo.store[key]
        XCTAssertEqual(savedConfig?.errorSamplePercent, 10)
        XCTAssertEqual(savedConfig?.wcdSamplePercent, 5)
    }
    
    func testGetConfigSuccess() {
        let key = "testConfig"
        let savedConfig = BTTSavedRemoteConfig(errorSamplePercent: 10, wcdSamplePercent: 5, dateSaved: Date().timeIntervalSince1970.milliseconds)
        configurationRepo.store[key] = savedConfig
        
        let fetchedConfig = configurationRepo.get(key)
        
        XCTAssertNotNil(fetchedConfig)
        XCTAssertEqual(fetchedConfig?.errorSamplePercent, 10)
        XCTAssertEqual(fetchedConfig?.wcdSamplePercent, 5)
    }
    
    func testGetConfigFailure_NoData() {
        let key = "nonExistingKey"
        let fetchedConfig = configurationRepo.get(key)
        XCTAssertNil(fetchedConfig)
    }
}
