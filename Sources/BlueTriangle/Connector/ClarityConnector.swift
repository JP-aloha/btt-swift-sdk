//
//  ClarityConnector.swift
//  
//
//  Created by Ashok Singh on 13/02/25.
//


struct ConnectorConfig{
    let clarityProjectID : String?
    let clarityEnabled : Bool?
}

internal struct ClarityRemoteConfigKeys {
    static let claritySessionURL = "claritySessionURL"
    static let clarityProjectID  = "clarityProjectID"
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
    
    init(_ logger : Logging){
        self.logger = logger
    }
   
    func start() {
        queue.async {
            
            guard let projectId = self.clarityProjectID, !self.isInitialized else{
                self.logger.info("BlueTriangle::ClarityConnector - Unable to initialize clarity")
                return
            }
            
            ClaritySDK.setOnSessionStartedCallback { _ in
                self.sessionURL =  ClaritySDK.getCurrentSessionUrl()
                if let sessionURL = self.sessionURL{
                    BlueTriangle.setCustomVariable("CV0", value: sessionURL)
                }
            }
            
            if ClaritySDK.isPaused(){
                ClaritySDK.resume()
                
                if let sessionURL = self.sessionURL{
                    BlueTriangle.setCustomVariable("CV0", value: sessionURL)
                }
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
        queue.async {
            if self.isInitialized{
                ClaritySDK.pause()
                BlueTriangle.clearCustomVariable("CV0")
                self.isInitialized = false
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
        
        guard let sessionURL = self.sessionURL, isInitialized else { return [:] }
        
        return [
            ClarityRemoteConfigKeys.claritySessionURL: sessionURL
        ]
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
