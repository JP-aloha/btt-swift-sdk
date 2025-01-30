//
//  SessionStore.swift
//  
//
//  Created by Ashok Singh on 07/11/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

class SessionStore {
    
    private let sessionKey = "SAVED_SESSION_DATA"
    
    func saveSession(_ session: SessionData) {
        if let encoded = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encoded, forKey: sessionKey)
        }
    }
    
    func retrieveSessionData() -> SessionData? {
        if let savedSession = UserDefaults.standard.object(forKey: sessionKey) as? Data {
            if let decodedSession = try? JSONDecoder().decode(SessionData.self, from: savedSession) {
                return decodedSession
            }
        }
        
        return nil
    }
    
    func isExpired() -> Bool{
        
        var isExpired : Bool = true
        
        if let session = retrieveSessionData(){
            let currentTime = Int64(Date().timeIntervalSince1970) * 1000
            if  currentTime > session.expiration{
                isExpired = true
            }else{
                isExpired = false
            }
        }else{
            isExpired = true
        }
        
        return isExpired
    }
    
    func removeSessionData() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        UserDefaults.standard.synchronize()
    }
}


class SessionData: Codable {
    let sessionID: Identifier
    var expiration: Millisecond
    var isNewSession: Bool
    var shouldNetworkCapture: Bool
    var networkSampleRate : Double
    var ignoreViewControllers: Set<String>
    
    init(expiration: Millisecond) {
        self.expiration = expiration
        self.sessionID =  SessionData.generateSessionID()
        self.isNewSession = true
        self.shouldNetworkCapture = false
        self.networkSampleRate = BlueTriangle.configuration.networkSampleRate
        self.ignoreViewControllers = BlueTriangle.configuration.ignoreViewControllers
    }
    
    private static func generateSessionID()-> Identifier {
        let sessionID = Identifier.random()
        return sessionID
    }
}
