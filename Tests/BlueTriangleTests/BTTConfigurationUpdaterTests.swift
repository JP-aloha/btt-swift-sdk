//
//  BTTConfigurationUpdaterTests.swift
//  
//
//  Created by Ashok Singh on 09/09/24.
//

import XCTest
@testable import BlueTriangle

final class BTTConfigurationUpdaterTests: XCTestCase {
    
    var mockConfigFetcher: MockBTTConfigurationFetcher!
    var mockConfigRepo: MockBTTConfigurationRepo!
    var configurationUpdater: BTTConfigurationUpdater!
    
    override func setUp() {
        super.setUp()
        mockConfigFetcher = MockBTTConfigurationFetcher()
        mockConfigRepo = MockBTTConfigurationRepo()
        configurationUpdater = BTTConfigurationUpdater(configFetcher: mockConfigFetcher, configRepo: mockConfigRepo)
    }
    
    override func tearDown() {
        mockConfigFetcher = nil
        mockConfigRepo = nil
        configurationUpdater = nil
        super.tearDown()
    }
    
    func testUpdateNewSessionUsesBufferConfig() {
        let bufferConfig = BTTSavedRemoteConfig(errorSamplePercent: 10, wcdSamplePercent: 5, dateSaved: Date().timeIntervalSince1970.milliseconds)
        mockConfigRepo.store[Constants.BTT_BUFFER_REMOTE_CONFIG_KEY] = bufferConfig
        
        let expectation = self.expectation(description: "completion called")
        
        configurationUpdater.update(true) { config in
            XCTAssertNotNil(config)
            XCTAssertEqual(config?.errorSamplePercent, 10)
            XCTAssertEqual(config?.wcdSamplePercent, 5)
            XCTAssertTrue(self.mockConfigFetcher.fetchCalled)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testUpdateNotNewSessionUsesCurrentConfig() {
        let currentConfig = BTTSavedRemoteConfig(errorSamplePercent: 15, wcdSamplePercent: 20, dateSaved: Date().timeIntervalSince1970.milliseconds)
        mockConfigRepo.store[Constants.BTT_CURRENT_REMOTE_CONFIG_KEY] = currentConfig
        
        let expectation = self.expectation(description: "completion called")
        
        configurationUpdater.update(false) { config in
            XCTAssertNotNil(config)
            XCTAssertEqual(config?.errorSamplePercent, 15)
            XCTAssertEqual(config?.wcdSamplePercent, 20)
            XCTAssertFalse(self.mockConfigFetcher.fetchCalled)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testUpdateFetchNewConfigAndSave() {
        let oldTime = Date().timeIntervalSince1970.milliseconds - (2 * .hour) // force an update by simulating old config
        let oldConfig = BTTSavedRemoteConfig(errorSamplePercent: 15, wcdSamplePercent: 20, dateSaved: oldTime)
        mockConfigRepo.store[Constants.BTT_CURRENT_REMOTE_CONFIG_KEY] = oldConfig
        
        let newConfig = BTTRemoteConfig(errorSamplePercent: 50, wcdSamplePercent: 60)
        mockConfigFetcher.configToReturn = newConfig
        
        let expectation = self.expectation(description: "completion called")
        
        configurationUpdater.update(false) { config in
            XCTAssertEqual(self.mockConfigRepo.store[Constants.BTT_BUFFER_REMOTE_CONFIG_KEY]?.errorSamplePercent, 50)
            XCTAssertEqual(self.mockConfigRepo.store[Constants.BTT_BUFFER_REMOTE_CONFIG_KEY]?.wcdSamplePercent, 60)
            XCTAssertTrue(self.mockConfigFetcher.fetchCalled)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}





