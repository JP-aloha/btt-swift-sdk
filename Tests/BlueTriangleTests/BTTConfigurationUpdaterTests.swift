//
//  BTTConfigurationUpdaterTests.swift
//  
//
//  Created by Ashok Singh on 09/09/24.
//

import XCTest
@testable import BlueTriangle

final class BTTConfigurationUpdaterTests: XCTestCase {
    
    
    var configUpdater: BTTConfigurationUpdater!
    var mockFetcher: MockBTTConfigurationFetcher!
    var mockRepo: MockBTTConfigurationRepo!
    
    let key = Constants.BTT_BUFFER_REMOTE_CONFIG_KEY
    
    override func setUp() {
        super.setUp()
        mockFetcher = MockBTTConfigurationFetcher()
        mockRepo = MockBTTConfigurationRepo()
        configUpdater = BTTConfigurationUpdater(configFetcher: mockFetcher, configRepo: mockRepo)
    }
    
    override func tearDown() {
        mockFetcher = nil
        mockRepo = nil
        configUpdater = nil
        super.tearDown()
    }

    func testUpdatePerformsFetchIfNewSession() {

        let config = BTTRemoteConfig(errorSamplePercent: 60, wcdSamplePercent: 75)
        mockFetcher.configToReturn = config
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        configUpdater.update(true) { hasChanged in
            
            let currentConfig = self.mockRepo.get()
            
            XCTAssertTrue(hasChanged, "Remote config has changed")
            XCTAssertTrue(self.mockFetcher.fetchCalled, "Fetch should be called in a new session")
            XCTAssertEqual(currentConfig?.wcdSamplePercent, config.wcdSamplePercent, "New config should be saved")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateSkipsFetchIfNotNewSessionAndWithinUpdatePeriod() {
        
        let config = BTTRemoteConfig(errorSamplePercent: 60, wcdSamplePercent: 75)
        mockRepo.save(config)
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        configUpdater.update(false) { hasChanged in
            XCTAssertFalse(hasChanged, "Remote config has not changed")
            XCTAssertFalse(self.mockFetcher.fetchCalled, "Fetch should not be called if within update period")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdatePerformsFetchIfNotNewSessionAndUpdatePeriodElapsed() {
        
        let apiConfig = BTTRemoteConfig(errorSamplePercent: 60, wcdSamplePercent: 75)
        mockFetcher.configToReturn = apiConfig
        
        
        let currentTime = Date().timeIntervalSince1970.milliseconds
        let storeConfig = BTTSavedRemoteConfig(errorSamplePercent: 50, wcdSamplePercent: 70, dateSaved: currentTime - Millisecond.hour * 2)
        mockRepo.store[key] = storeConfig
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        configUpdater.update(false) { hasChanged in
            
            let currentConfig = self.mockRepo.get()
            
            XCTAssertTrue(hasChanged, "Remote config has changed")
            XCTAssertTrue(self.mockFetcher.fetchCalled, "Fetch should be called in a new session")
            XCTAssertEqual(currentConfig?.wcdSamplePercent, apiConfig.wcdSamplePercent, "Current config is not updated")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}





