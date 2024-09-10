//
//  MockBTTConfigurationFetcher.swift
//  
//
//  Created by Ashok Singh on 10/09/24.
//

import XCTest
@testable import BlueTriangle

class MockBTTConfigurationFetcher: ConfigurationFetcher {
    var configToReturn: BTTRemoteConfig?
    
    func fetch(completion: @escaping (BTTRemoteConfig?) -> Void) {
        completion(configToReturn)
    }
}
