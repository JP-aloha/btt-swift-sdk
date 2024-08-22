//
//  SessionManager.swift
//  
//
//  Created by Ashok Singh on 19/08/24.
//

import Foundation
import UIKit

class SessionData: Codable {
    var sessionID: Identifier
    var expiration: Millisecond

    init(sessionID: Identifier, expiration: Millisecond) {
        self.sessionID = sessionID
        self.expiration = expiration
    }
}

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
}

class SessionManager {
   
    private let expirationDuration: Millisecond = 1 * 60 * 1000 // 30 minutes in seconds
    private let  sessionStore = SessionStore()
    private var currentSession : SessionData?
    
    func start(){
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { notification in
            self.appOffScreen()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { notification in
            self.appOnScreen()
        }
        
        self.updateSession()
    }
    
    private func appOffScreen(){
        if let session = currentSession{
            session.expiration = expirynDuration()
            sessionStore.saveSession(session)
        }
    }
    
    private func appOnScreen(){
        self.updateSession()
    }
    
    private func invalidateSession(){
        if sessionStore.isExpired(){
            let session = SessionData(sessionID: generateSessionID(), expiration: expirynDuration())
            currentSession = session
            sessionStore.saveSession(session)
        }else{
            currentSession = sessionStore.retrieveSessionData()
        }
    }
    
    private func updateSession(){
        if let currentSession = self.getCurrentSession(){
            BlueTriangle.updateSession(currentSession.sessionID)
        }
    }

    private func generateSessionID()-> Identifier {
        return Identifier.random()
    }

    private func getCurrentSession() -> SessionData? {
        self.invalidateSession()
        return currentSession
    }
    
    private func expirynDuration()-> Millisecond {
        let expiry = Int64(Date().timeIntervalSince1970) * 1000 + expirationDuration
        return expiry
    }
}
