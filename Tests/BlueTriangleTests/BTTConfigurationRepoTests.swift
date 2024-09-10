//
//  BTTConfigurationRepoTests.swift
//  
//
//  Created by Ashok Singh on 09/09/24.
//

import XCTest
@testable import BlueTriangle

final class BTTConfigurationRepoTests: XCTestCase {

    var configRepo: ConfigurationRepo!
    
    override func setUp() {
        super.setUp()
        configRepo = BTTConfigurationRepo()
    }
    
    override func tearDown() {
        configRepo.clear()
        configRepo = nil
        super.tearDown()
    }
    
    func testSaveConfig() {
      
        configRepo = BTTConfigurationRepo()
        configRepo.clear()
        
        configRepo = BTTConfigurationRepo()
        let config = BTTRemoteConfig(errorSamplePercent: 10, wcdSamplePercent: 20)
        configRepo.save(config)
        
        configRepo = BTTConfigurationRepo()
        let retrievedConfig = configRepo.get()
        
        XCTAssertNotNil(retrievedConfig)
        
        if let remoteConfig = retrievedConfig {
            XCTAssertEqual(remoteConfig.errorSamplePercent, 10)
            XCTAssertEqual(remoteConfig.wcdSamplePercent, 20)
        } else {
            XCTFail("Data was not saved correctly")
        }
    }
    
    func testGetConfig() {
       
        configRepo = BTTConfigurationRepo()
        configRepo.clear()
        
        configRepo = BTTConfigurationRepo()
        let config = BTTRemoteConfig(errorSamplePercent: 20, wcdSamplePercent: 30)
        configRepo.save(config)
        
        configRepo = BTTConfigurationRepo()
        let retrievedConfig = configRepo.get()
        
        XCTAssertNotNil(retrievedConfig)
        
        if let remoteConfig = retrievedConfig {
            XCTAssertEqual(remoteConfig.errorSamplePercent, 20)
            XCTAssertEqual(remoteConfig.wcdSamplePercent, 30)
        } else {
            XCTFail("Data was not get correctly")
        }
    }
    
    func testUpdateConfig() {
       
        configRepo = BTTConfigurationRepo()
        configRepo.clear()
        
        configRepo = BTTConfigurationRepo()
        let configSave = BTTRemoteConfig(errorSamplePercent: 10, wcdSamplePercent: 20)
        configRepo.save(configSave)
        
        configRepo = BTTConfigurationRepo()
        let configUpdate = BTTRemoteConfig(errorSamplePercent: 30, wcdSamplePercent: 40)
        configRepo.save(configUpdate)
        
        configRepo = BTTConfigurationRepo()
        let retrievedConfig = configRepo.get()
        
        XCTAssertNotNil(retrievedConfig)
        
        if let remoteConfig = retrievedConfig {
            XCTAssertEqual(remoteConfig.errorSamplePercent, 30)
            XCTAssertEqual(remoteConfig.wcdSamplePercent, 40)
        } else {
            XCTFail("Data was not updated correctly")
        }
    }
    
    func testGetConfigReturnsNilWhenDataIsNotAvailable() {
       
        configRepo = BTTConfigurationRepo()
        configRepo.clear()
        
        configRepo = BTTConfigurationRepo()
        let retrievedConfig = configRepo.get()
        XCTAssertNil(retrievedConfig)
    }
}
