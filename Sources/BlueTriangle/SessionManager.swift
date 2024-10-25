//
//  SessionManager.swift
//  
//
//  Created by Ashok Singh on 19/08/24.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

class SessionData: Codable {
    var sessionID: Identifier
    var expiration: Millisecond
    var isNewSession: Bool
    var shouldNetworkCapture: Bool

    init(expiration: Millisecond) {
        self.expiration = expiration
        self.sessionID =  SessionData.generateSessionID()
        self.isNewSession = true
        self.shouldNetworkCapture = .random(probability: BlueTriangle.configuration.networkSampleRate)
    }
    
    private static func generateSessionID()-> Identifier {
        let sessionID = Identifier.random()
        return sessionID
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
   
    private let lock = NSLock()
    private var expirationDurationInMS: Millisecond = 30 * 60 * 1000
    private let  sessionStore = SessionStore()
    private var currentSession : SessionData?
    private let notificationQueue = OperationQueue()
    
    public func start(with  expiry : Millisecond){
        
        expirationDurationInMS = expiry
        
#if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: notificationQueue) { notification in
            self.appOffScreen()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: notificationQueue) { notification in
            self.onLaunch()
        }
#endif

        self.onSessionUpdate()
    }
    
    private func appOffScreen(){
        if let session = currentSession {
            session.expiration = expiryDuration()
            session.isNewSession = false
            currentSession = session
            sessionStore.saveSession(session)
        }
    }
    
    private func onLaunch(){
        self.onSessionUpdate()
    }
    
    private func invalidateSession() -> SessionData{
        
        if sessionStore.isExpired(){
            let session = SessionData(expiration: expiryDuration())
            currentSession = session
            session.isNewSession = true
            sessionStore.saveSession(session)
            return session
        }else{
            guard let session = currentSession else {
                let session = sessionStore.retrieveSessionData()
                session!.isNewSession = false
                currentSession = session
                sessionStore.saveSession(session!)
                return session!
            }
            return session
        }
    }
    
    private func onSessionUpdate(){
        BlueTriangle.updateSession(getSessionData())
    }
    
    public func refreshSession(){
        let session = getSessionData()
        if session.isNewSession {
            session.shouldNetworkCapture =  .random(probability: BlueTriangle.configuration.networkSampleRate)
            sessionStore.saveSession(session)
            print("Recalculate shouldNetworkCapture on new session")
        }
    }

    public func getSessionData() -> SessionData {
        lock.sync {
            let updatedSession = self.invalidateSession()
            return updatedSession
        }
    }
    
    private func expiryDuration()-> Millisecond {
        let expiry = Int64(Date().timeIntervalSince1970) * 1000 + expirationDurationInMS
        return expiry
    }
}
