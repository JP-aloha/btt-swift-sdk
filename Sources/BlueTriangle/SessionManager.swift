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
    
    private let sessionKey = "SavedSession"
    
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
   
    private let sessionTimeout: Millisecond = 1 * 60 * 1000 // 30 minutes in seconds
    private let  store = SessionStore()
    private var currentSession : SessionData?
    
    func start(){
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { notification in
            self.didEnterBackground()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { notification in
            self.appWillEnterForeground()
        }
        
        print("SessionManager : init")
        self.updateSession()
    }
    
    @objc private func didEnterBackground() {
        print("SessionManager : didEnterBackground")
        self.appOffScreen()
    }

    @objc private func appWillEnterForeground() {
        print("SessionManager : appWillEnterForeground")
        self.appOnScreen()
    }
    
    private func appOffScreen(){
        if let session = currentSession{
            let expiry = Int64(Date().timeIntervalSince1970) * 1000 + sessionTimeout
            session.expiration = expiry
            store.saveSession(session)
            print("Saved Session \(session.sessionID)")
        }
    }
    
    private func appOnScreen(){
        self.updateSession()
    }
    
    private func invalidateSession(){
        if store.isExpired(){
            let expiry = Int64(Date().timeIntervalSince1970) * 1000 + sessionTimeout
            let session = SessionData(sessionID: generateSessionID(), expiration: expiry)
            currentSession = session
            store.saveSession(session)
        }else{
            currentSession = store.retrieveSessionData()
        }
        
        print("Fetched Session \(currentSession?.sessionID)")
    }
    
    internal func updateSession(){
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
}
