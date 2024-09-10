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
    var sessionMock: URLSession!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        let config = URLSessionConfiguration.default
        config.protocolClasses = [MockRemoteConfigURL.self]
        sessionMock = URLSession(configuration: config)
        
        configurationFetcher = BTTConfigurationFetcher(session: sessionMock, cancellable: cancellables)
    }

    override func tearDown() {
        configurationFetcher = nil
        cancellables = nil
        sessionMock = nil
        super.tearDown()
    }

    func testFetchConfigurationSuccess() {
        let mockConfig = BTTRemoteConfig(errorSamplePercent: 10, wcdSamplePercent: 20)
        let mockData = try! JSONEncoder().encode(mockConfig)
        
        MockRemoteConfigURL.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!
            return (response, mockData)
        }

        let expectation = self.expectation(description: "Completion handler called for success configuration")

        configurationFetcher.fetch { config in
            // Assert
            XCTAssertNotNil(config)
            XCTAssertEqual(config?.errorSamplePercent, 10)
            XCTAssertEqual(config?.wcdSamplePercent, 20)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testFetchConfigurationFailure() {
        MockRemoteConfigURL.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!,
                                           statusCode: 500,
                                           httpVersion: nil,
                                           headerFields: nil)!
            return (response, Data())
        }

        let expectation = self.expectation(description: "Completion handler called for failure configuration")

        configurationFetcher.fetch { config in
            XCTAssertNil(config)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}


