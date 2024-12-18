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
    var configAck: RemoteConfigAckReporter!
    var mockFetcher: MockBTTConfigurationFetcher!
    var mockRepo: MockBTTConfigurationRepo!
    var loger : LoggerMock!
    var mocUpdater: UploaderMock!
    
    let key = BlueTriangle.siteID
    
    override func setUp() {
        super.setUp()
        loger = LoggerMock()
        mocUpdater = UploaderMock()
        mockFetcher = MockBTTConfigurationFetcher()
        mockRepo = MockBTTConfigurationRepo()
        configAck = RemoteConfigAckReporter(logger: loger, uploader: mocUpdater)
        configUpdater = BTTConfigurationUpdater(configFetcher: mockFetcher,
                                                configRepo: mockRepo,
                                                logger: loger, 
                                                configAck: configAck)
    }
    
    override func tearDown() {
        mockFetcher = nil
        mockRepo = nil
        configUpdater = nil
        super.tearDown()
    }

    func testUpdatePerformsFetchIfNewSession() {

        let config = BTTRemoteConfig(networkSampleRateSDK: 75, 
                                     enableRemoteConfigAck: false,
                                     ignoreScreens: [])
        mockFetcher.configToReturn = config
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        configUpdater.update(true) {
            let currentConfig = self.mockRepo.get()
            XCTAssertTrue(self.mockFetcher.fetchCalled, "Fetch should be called in a new session")
            XCTAssertEqual(currentConfig?.networkSampleRateSDK, config.networkSampleRateSDK, "New config should be saved")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateSkipsFetchIfNotNewSessionAndWithinUpdatePeriod() {
        
        let config = BTTRemoteConfig(networkSampleRateSDK: 75, 
                                     enableRemoteConfigAck: false,
                                     ignoreScreens: [])
        mockRepo.save(config)
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        configUpdater.update(false) {
            XCTAssertFalse(self.mockFetcher.fetchCalled, "Fetch should not be called if within update period")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdatePerformsFetchIfNotNewSessionAndUpdatePeriodElapsed() {
        
        let apiConfig = BTTRemoteConfig(networkSampleRateSDK: 75, 
                                        enableRemoteConfigAck: false,
                                        ignoreScreens: [])
        mockFetcher.configToReturn = apiConfig
        
        
        let currentTime = Date().timeIntervalSince1970.milliseconds
        let storeConfig = BTTSavedRemoteConfig(networkSampleRateSDK: 70, enableRemoteConfigAck: false, ignoreScreens: [], dateSaved: currentTime - Millisecond.hour * 2)
        mockRepo.store[key] = storeConfig
        
        let expectation = XCTestExpectation(description: "Completion handler called")
        
        configUpdater.update(false) {
            let currentConfig = self.mockRepo.get()
            XCTAssertTrue(self.mockFetcher.fetchCalled, "Fetch should be called in a new session")
            XCTAssertEqual(currentConfig?.networkSampleRateSDK, apiConfig.networkSampleRateSDK, "Current config is not updated")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}





