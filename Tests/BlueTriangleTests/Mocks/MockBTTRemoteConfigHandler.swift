//
//  MockBTTRemoteConfigHandler.swift
//  
//
//  Created by Ashok Singh on 10/09/24.
//

import XCTest
@testable import BlueTriangle

class MockBTTRemoteConfigHandler: RemoteConfigHandler {
    var remoteConfig: BTTRemoteConfig?
   
    func updateRemoteConfig(_ config: BTTRemoteConfig) {
        remoteConfig = config
    }
}
