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
        let config = BTTRemoteConfig(networkSampleRateSDK: 5,
                                     enableRemoteConfigAck: false,
                                     enableAllTracking: true,
                                     enableScreenTracking: true,
                                     enableGrouping: true,
                                     groupingIdleTime: 2,
                                     ignoreScreens: [],
                                     enableCrashTracking: true,
                                     enableANRTracking: true,
                                     enableMemoryWarning: true,
                                     enableLaunchTime: true,
                                     enableWebViewStitching: true,
                                     enableNetworkStateTracking: true,
                                     enableGroupingTapDetection: true,
                                     checkoutTrackingEnabled: false,
                                     checkoutClassName: [],
                                     checkoutURL: "",
                                     checkoutAmount: 1.0,
                                     checkoutCartCount: 1,
                                     checkoutCartCountCheckout: 1,
                                     checkoutOrderNumber: "",
                                     checkoutTimeValue: 100)
        
        configurationRepo.save(config)
        
        XCTAssertNotNil(configurationRepo.store[key])
        
        let savedConfig = configurationRepo.store[key]
        XCTAssertEqual(savedConfig?.networkSampleRateSDK, 5)
    }
    
    func testGetConfigSuccess() {
        let savedConfig = BTTSavedRemoteConfig(networkSampleRateSDK: 5,
                                               enableRemoteConfigAck: false,
                                               enableAllTracking: true,
                                               enableScreenTracking: true,
                                               enableGrouping: true,
                                               groupingIdleTime: 2,
                                               ignoreScreens: [],
                                               enableCrashTracking: true,
                                               enableANRTracking: true,
                                               enableMemoryWarning: true,
                                               enableLaunchTime: true,
                                               enableWebViewStitching: true,
                                               enableNetworkStateTracking: true,
                                               enableGroupingTapDetection: true,
                                               checkoutTrackingEnabled: false,
                                               checkoutClassName: [],
                                               checkoutURL: "",
                                               checkoutAmount: 1.0,
                                               checkoutCartCount: 1,
                                               checkoutCartCountCheckout: 1,
                                               checkoutOrderNumber: "",
                                               checkoutTimeValue: 100,
                                               dateSaved: Date().timeIntervalSince1970.milliseconds)

        configurationRepo.store[key] = savedConfig
        
        let fetchedConfig = configurationRepo.get()
        
        XCTAssertNotNil(fetchedConfig)
        XCTAssertEqual(fetchedConfig?.networkSampleRateSDK, 5)
    }
    
    func testSaveAndRetrieveNilConfig() {
        let retrievedConfig = configurationRepo.get()
        XCTAssertNil(retrievedConfig)
    }
}
