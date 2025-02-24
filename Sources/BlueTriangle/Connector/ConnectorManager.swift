//
//  ConnectorManager.swift
//  
//
//  Created by Ashok Singh on 14/02/25.
//

import Foundation

class ConnectorManager {

    private let connectorsProvider: ConnectorsProviderProtocol

    init(connectorsProvider: ConnectorsProviderProtocol) {
        self.connectorsProvider = connectorsProvider
    }

    /// Configures connectors when the SDK is enabled based on the remote configuration field.
    /// It initializes connectors with the required configuration using session data.
    func configureConnectors() {
        if let session = BlueTriangle.sessionData(){
            let connectors = connectorsProvider.getConnectors()
            let connectorConfig = ConnectorConfig(clarityProjectID: session.clarityProjectID, 
                                                  clarityEnabled: session.clarityEnabled)
            
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
    
    /// Fetches payloads from all connectors and merges them into a single dictionary.
    /// - Returns: A dictionary containing all connector payloads, where keys are payload identifiers
    ///   and values are optional string data.
    func getAllPayloads() -> [String: String?] {
        var mergedPayload: [String: String?] = [:]
        
        let connectors = connectorsProvider.getConnectors()
        for connector in connectors {
            let payload = connector.getPayload()
            for (key, value) in payload {
                mergedPayload[key] = value
            }
        }
        
        return mergedPayload
    }
}
