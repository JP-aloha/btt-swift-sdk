//
//  ConnectorManager.swift
//  
//
//  Created by JP on 14/02/25.
//  Copyright © 2023 Blue Triangle. All rights reserved.

import Foundation

class ConnectorController {

    private let connectorsProvider: ConnectorsProviderProtocol

    init(connectorsProvider: ConnectorsProviderProtocol) {
        self.connectorsProvider = connectorsProvider
    }

    /// Configures connectors when the SDK is enabled based on the remote configuration field.
    /// It initializes connectors with the required configuration using session data.
    func configureConnectors() {
        if let session = BlueTriangle.sessionData(){
            let connectors = connectorsProvider.getConnectors()
           /* let connectorConfig = ConnectorConfig(clarityProjectID: session.clarityProjectID,
                                                  clarityEnabled: session.clarityEnabled)*/
            let connectorConfig = ConnectorConfig(clarityProjectID: "jtjobmhr3i",
                                                  clarityEnabled: true)
            
            for connector in connectors {
                connector.configure(connectorConfig)
            }
        }
    }
    
    /// Stops all connectors forcefully when the SDK is disabled.
    /// This ensures that no connectors remain active in the disabled state.
    func stopAllConnectors() {
        let connectors = connectorsProvider.getConnectors()
        for connector in connectors {
            connector.stop()
        }
    }  
    
    /// Retrieves all connectors payload containing platform-specific information that is sent to the **NATIVEAPP**.
    /// - Returns: A dictionary containing key-value pairs of native-specific information.
    func getAllNativePayloads() -> [String: String?] {
        var mergedPayload: [String: String?] = [:]
        
        let connectors = connectorsProvider.getConnectors()
        for connector in connectors {
            let payload = connector.getNativePayload()
            for (key, value) in payload {
                mergedPayload[key] = value // Overwrites duplicate keys
            }
        }
        
        return mergedPayload
    }

    /// Retrieves all connectors  payload containing information that is sent to the main payload.
    /// - Returns: A dictionary containing key-value pairs of general information.
    func getAllGeneralPayloads() -> [String: String?] {
        var mergedPayload: [String: String?] = [:]
        
        let connectors = connectorsProvider.getConnectors()
        for connector in connectors {
            let payload = connector.getGeneralPayload()
            for (key, value) in payload {
                mergedPayload[key] = value // Overwrites duplicate keys
            }
        }
        
        return mergedPayload
    }
}
