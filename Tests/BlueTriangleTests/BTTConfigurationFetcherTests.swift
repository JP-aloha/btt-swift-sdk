//
//  BTTConfigurationFetcherTests.swift
//  
//
//  Created by Ashok Singh on 09/09/24.
//

import XCTest
import Combine
@testable import BlueTriangle

final class BTTConfigurationFetcherTests: XCTestCase {

    var configurationFetcher: ConfigurationFetcher!
    var cancellables: Set<AnyCancellable>!
    let logger: LoggerMock = .init()
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        configurationFetcher = BTTConfigurationFetcher(logger: logger)
    }

    override func tearDown() {
        configurationFetcher = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testFetchConfigurationSuccess() {

        let logger: LoggerMock = .init()
        let mockNetworking: Networking = { request in
            
            let mockConfig = BTTRemoteConfig(networkSampleRateSDK: 20,
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
            
            let mockData = try! JSONEncoder().encode(mockConfig)
            
            let response = HTTPURLResponse(url: request.url,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!
            let httpResponse = HTTPResponse(value: mockData, response: response)
            
            return Just(httpResponse)
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        }
        
        configurationFetcher = BTTConfigurationFetcher(
            logger: logger, rootUrl: Constants.configEndPoint(for: BlueTriangle.siteID),
            cancellable: cancellables,
            networking: mockNetworking
        )
        
        let expectation = self.expectation(description: "Completion handler called for successful configuration fetch")
        
        configurationFetcher.fetch { config , error in
            XCTAssertNotNil(config, "Config should not be nil on success")
            XCTAssertEqual(config?.networkSampleRateSDK, 20, "WCD sample percent should be 20")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testFetchConfigurationFailure() {
        // Mock networking to return a failure response
        let mockNetworking: Networking = { request in
            return Fail<HTTPResponse<Data>, NetworkError>(error: .noData)
                .eraseToAnyPublisher()
        }
        let logger: LoggerMock = .init()
        configurationFetcher = BTTConfigurationFetcher(
            logger: logger, rootUrl: Constants.configEndPoint(for: BlueTriangle.siteID),
            cancellable: Set<AnyCancellable>(),
            networking: mockNetworking
        )
        
        let expectation = self.expectation(description: "Completion handler called for failed configuration fetch")
        
        configurationFetcher.fetch { config, error  in
            XCTAssertNil(config, "Config should be nil on failure")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}


