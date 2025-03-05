//
//  ClarityConnector.swift
//  
//
//  Created by JP on 13/02/25.
//  Copyright © 2023 Blue Triangle. All rights reserved.


struct ConnectorConfig{
    let clarityProjectID : String?
    let clarityEnabled : Bool?
}

internal struct ClarityRemoteConfigKeys {
    static let claritySessionURL = "claritySessionURL"
    static let clarityProjectID  = "clarityProjectID"
}

internal struct ClarityCVKeys {
    static let claritySessionURL = "CV0"
}

/// Protocol defining the necessary methods for a connector implementation.
protocol ConnectorProtocol {
    /// Starts the connector. This function should initialize and start connector.
    /// It should be called when the connector is ready to begin its operations.
    func start()
    /// Stops the connector. This function should pause or stop connector..
    /// It should be called when the connector is no longer needed
    func stop()
    
    /// Retrieves a connector payload containing information that is sent to the main payload.
    /// - Returns: A dictionary containing key-value pairs of general information.
    func getGeneralPayload() -> [String: String?]
       
    /// Retrieves a connector payload containing platform-specific information that is sent to the **NATIVEAPP**.
    /// - Returns: A dictionary containing key-value pairs of native-specific information.
    func getNativePayload() -> [String: String?]
    
    /// Configures the connector with the provided configuration.
    /// This function should be called to set up the connector with necessary configurations before starting it.
    /// - Parameter config: The configuration object containing settings for the connector.
    func configure(_ config : ConnectorConfig)
}

#if canImport(Clarity)

import Foundation
import Clarity

class ClarityConnector: ConnectorProtocol{
    private let queue = DispatchQueue(label: "com.bluetriangle.clarity.connector", qos: .userInitiated, autoreleaseFrequency: .workItem, target: DispatchQueue.main)
    private(set) var clarityProjectID : String?
    private(set) var clarityEnabled : Bool?
    private(set) var isInitialized : Bool = false
    private(set) var sessionURL : String?
    private(set) var logger: Logging
    private(set) var cvAdapter: CustomVariableAdapterProtocol
    
    init(_ logger: Logging, 
         cvAdapter: CustomVariableAdapterProtocol) {
        self.logger = logger
        self.cvAdapter = cvAdapter
    }

    func start() {
        DispatchQueue.main.async {
            
            guard let projectId = self.clarityProjectID, !self.isInitialized else{
                self.logger.info("BlueTriangle::ClarityConnector - Unable to initialize clarity")
                return
            }
            
            ClaritySDK.setOnSessionStartedCallback { _ in
                self.sessionURL =  ClaritySDK.getCurrentSessionUrl()
                self.cvAdapter.setConnectorCustomVariable(value: self.sessionURL, forKey: ClarityCVKeys.claritySessionURL)
            }
            
            if ClaritySDK.isPaused(){
                ClaritySDK.resume()
                self.cvAdapter.setConnectorCustomVariable(value: self.sessionURL, forKey: ClarityCVKeys.claritySessionURL)
                self.logger.info("BlueTriangle::ClarityConnector - Successfully resume clarity")
            }
            else{
                let clarityConfig = ClarityConfig(projectId: projectId)
                ClaritySDK.initialize(config: clarityConfig)
                self.logger.info("BlueTriangle::ClarityConnector - Successfully initialized clarity")
            }
            
            self.isInitialized = true
        }
    }
    
    func stop() {
        DispatchQueue.main.async {
            if self.isInitialized{
                ClaritySDK.pause()
                self.isInitialized = false
                self.cvAdapter.clearConnectorCustomVariable(forKey: ClarityCVKeys.claritySessionURL)
                self.logger.info("BlueTriangle::ClarityConnector - Successfully paused clarity")
            }
        }
    }

    func configure(_ config : ConnectorConfig) {
        self.clarityProjectID = config.clarityProjectID
        self.clarityEnabled = config.clarityEnabled
        self.updateStatus()
    }
    
    func getNativePayload() -> [String: String?] {
        
        guard let projectId = clarityProjectID, isInitialized else { return [:] }
        
        return [
            ClarityRemoteConfigKeys.clarityProjectID: projectId
        ]
    }
    
    func getGeneralPayload() -> [String: String?] {
        
        guard isInitialized else { return [:] }
        
        return [:]
    }

}

extension ClarityConnector{

    private var canActivate: Bool {
        return clarityEnabled == true && clarityProjectID != nil
    }
    
    private func updateStatus(){
        if canActivate {
            self.start()
        }else{
            self.stop()
        }
    }
}

#endif
