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

internal struct ClarityKeys {
    static let claritySessionURL = "claritySessionURL"
    static let clarityProjectID  = "clarityProjectID"
}

protocol ConnectorProtocol {
    func start()
    func stop()
    func getPayload() -> [String: String?]
    func configure(_ config : ConnectorConfig)
}

#if canImport(Clarity)

import Foundation
import Clarity

class ClarityConnector: ConnectorProtocol{
    private let queue = DispatchQueue(label: "com.bluetriangle.clarity.connector", qos: .userInitiated, autoreleaseFrequency: .workItem)
    private(set) var previousProjectID : String?
    private(set) var clarityProjectID : String?
    private(set) var clarityEnabled : Bool?
    private(set) var isConnected : Bool = false
    private(set) var sessionURL : String?
   
    func start() {
        queue.async {
           
            guard self.isNeedCeconnect else{
                return
            }
            
            if let projectId = self.clarityProjectID{
                DispatchQueue.main.async {
                    if ClaritySDK.isPaused(), !self.hasChange{
                        ClaritySDK.resume()
                    }
                    else{
                        let clarityConfig = ClarityConfig(projectId: projectId)
                        ClaritySDK.initialize(config: clarityConfig)
                        self.previousProjectID = self.clarityProjectID
                    }
                    
                    ClaritySDK.setOnSessionStartedCallback { url in
                        self.sessionURL =  ClaritySDK.getCurrentSessionUrl()
                        print("ClaritySDK session url \(String(describing: self.sessionURL))")
                    }
                    
                    self.isConnected = true
                    print("ClaritySDK connected \(projectId)")
                }
            }
        }
    }
    
    func stop() {
        queue.async {
            DispatchQueue.main.async {
                if self.isConnected{
                    ClaritySDK.pause()
                    self.isConnected = false
                    print("ClaritySDK disconnected")
                }
            }
        }
    }

    func configure(_ config : ConnectorConfig) {
        self.clarityProjectID = config.clarityProjectID
        self.clarityEnabled = config.clarityEnabled
        self.updateStatus()
    }
    
    func getPayload() -> [String: String?] {
        
        guard let projectId = clarityProjectID, isConnected else { return [:] }

        // Construct and return the payload
        if let sessionURL = self.sessionURL {
            return [
                ClarityKeys.clarityProjectID: projectId,
                ClarityKeys.claritySessionURL: sessionURL
            ]
        }
        
        return [:]
    }

}

extension ClarityConnector{
    
    private var isNeedCeconnect : Bool {
        return !isConnected || hasChange
    }
    
    private var hasChange: Bool {
        return previousProjectID != clarityProjectID
    }
    
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
