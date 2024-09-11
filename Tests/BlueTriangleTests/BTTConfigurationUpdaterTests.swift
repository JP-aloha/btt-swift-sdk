//
//  BTTConfigurationUpdaterTests.swift
//  
//
//  Created by Ashok Singh on 09/09/24.
//

import XCTest
@testable import BlueTriangle

final class BTTConfigurationUpdaterTests: XCTestCase {
    
    var updater: BTTConfigurationUpdater!
    var mockFetcher: MockBTTConfigurationFetcher!
    var mockRepo: MockBTTConfigurationRepo!
    var mockHandler: MockBTTRemoteConfigHandler!
    
    override func setUp() {
        super.setUp()
        mockFetcher = MockBTTConfigurationFetcher()
        mockRepo = MockBTTConfigurationRepo()
        mockHandler = MockBTTRemoteConfigHandler()
        updater = BTTConfigurationUpdater(configFetcher: mockFetcher, configRepo: mockRepo, configHandler: mockHandler)
    }
    
    override func tearDown() {
        updater = nil
        mockFetcher = nil
        mockRepo = nil
        mockHandler = nil
        super.tearDown()
    }
    
    func testNoUpdateNeededWithinUpdatePeriod() {
        
        let savedConfig = BTTRemoteConfig(errorSamplePercent: 10,
                                          wcdSamplePercent: 20)
        mockRepo.save(savedConfig)
        
        let expectation = self.expectation(description: "Completion handler no update needed")
        
        updater.update {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(mockFetcher.configToReturn)
        XCTAssertEqual(mockRepo.get()?.wcdSamplePercent, savedConfig.wcdSamplePercent)
        XCTAssertNil(mockHandler.remoteConfig?.wcdSamplePercent)
    }
    
    func testUpdateNeededWhenNoConfigExist() {
        
        mockFetcher.configToReturn = BTTRemoteConfig(errorSamplePercent: 20, wcdSamplePercent: 50)
        
        let expectation = self.expectation(description: "Completion test update needed when no config exist ")
        
        updater.update {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertEqual(mockRepo.get()?.wcdSamplePercent, 50)
        XCTAssertEqual(mockHandler.remoteConfig?.wcdSamplePercent, 50)
    }
    
    func testUpdateNeededWhenAllReadyOldConfigExist() {
        
        let savedConfig = BTTRemoteConfig(errorSamplePercent: 10,
                                          wcdSamplePercent: 20)
        mockRepo.save(savedConfig)
        
        let getConfig = mockRepo.get()
        getConfig?.dateSaved = Date().addingTimeInterval(-3600).timeIntervalSince1970.milliseconds
        
        mockFetcher.configToReturn = BTTRemoteConfig(errorSamplePercent: 20, wcdSamplePercent: 50)
        
        let expectation = self.expectation(description: "Completion test update needed when allready old config exist")
        
        updater.update {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertEqual(mockRepo.get()?.wcdSamplePercent, 50)
        XCTAssertEqual(mockHandler.remoteConfig?.wcdSamplePercent, 50)
    }
    
    func testNoUpdateNeededWhenNewConfigIsSameAsOldConfig() {
        
        let savedConfig = BTTRemoteConfig(errorSamplePercent: 10,
                                          wcdSamplePercent: 20)
        mockRepo.save(savedConfig)
        
        let getConfig = mockRepo.get()
        getConfig?.dateSaved = Date().addingTimeInterval(-3600).timeIntervalSince1970.milliseconds
        
        mockFetcher.configToReturn = savedConfig
        
        let expectation = self.expectation(description: "Completion test when new config is same as old config")
        
        updater.update {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertEqual(mockRepo.get()?.wcdSamplePercent, 20)
        XCTAssertNil(mockHandler.remoteConfig?.wcdSamplePercent)
    }
    
}





