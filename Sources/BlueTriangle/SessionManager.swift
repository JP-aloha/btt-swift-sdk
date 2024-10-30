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

class SessionManager {
   
    private let lock = NSLock()
    private var expirationDurationInMS: Millisecond = 30 * 60 * 1000
    private let  sessionStore = SessionStore()
    private var currentSession : SessionData?
   
    private let queue = DispatchQueue(label: "com.bluetriangle.remote", qos: .userInitiated, autoreleaseFrequency: .workItem)
    private let configFetcher = BTTConfigurationFetcher()
    private let configRepo = BTTConfigurationRepo()
    lazy var updater = BTTConfigurationUpdater(configFetcher: configFetcher, configRepo: configRepo)

    
    public func start(with  expiry : Millisecond){
        
        expirationDurationInMS = expiry
        
#if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { notification in
            self.appOffScreen()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { notification in
            self.onLaunch()
        }
#endif

        self.updateSession()
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
        self.updateSession()
        self.updateRemoteConfig()
    }
    
    
    private func updateSession(){
        BlueTriangle.updateSession(getSessionData())
    }
    
    private func updateRemoteConfig(){
        queue.async {
            if let isNewSession = self.currentSession?.isNewSession {
                self.updater.update(isNewSession) { hasChanged in
                    if hasChanged{
                        self.reloadSession()
                        BlueTriangle.refreshCaptureRequests()
                    }
                }
            }
        }
    }
    
    private func invalidateSession() -> SessionData{
        
        if sessionStore.isExpired(){
            let session = SessionData(expiration: expiryDuration())
            session.isNewSession = true
            currentSession = session
            reloadSession()
            sessionStore.saveSession(session)
           
            return session
        }
        else{
            
            guard let session = currentSession else {
                let session = sessionStore.retrieveSessionData()
                session!.isNewSession = false
                currentSession = session
                reloadSession()
                sessionStore.saveSession(session!)
               
                return session!
            }
            
            return session
        }
    }
    
    private func reloadSession(){
        
        if let session = currentSession {
            if session.isNewSession{
                configRepo.synchronize()
                session.remoteConfig.networkSampleRate = BlueTriangle.configuration.networkSampleRate
                session.remoteConfig.shouldNetworkCapture =  .random(probability: BlueTriangle.configuration.networkSampleRate)
                sessionStore.saveSession(session)
                print("BlueTriangle sample rate on change : \(session.remoteConfig.networkSampleRate)")
            }
            else{
                BlueTriangle.updateNetworkSampleRate(session.remoteConfig.networkSampleRate)
                print("BlueTriangle sample rate on old value : \(session.remoteConfig.networkSampleRate)")
            }
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


class SessionData: Codable {
    var sessionID: Identifier
    var expiration: Millisecond
    var isNewSession: Bool
    var remoteConfig : RemoteConfigData

    init(expiration: Millisecond) {
        self.expiration = expiration
        self.sessionID =  SessionData.generateSessionID()
        self.isNewSession = true
        self.remoteConfig = RemoteConfigData()
    }
    
    private static func generateSessionID()-> Identifier {
        let sessionID = Identifier.random()
        return sessionID
    }
}

class RemoteConfigData : Codable{
    var shouldNetworkCapture: Bool = false
    var networkSampleRate: Double = BlueTriangle.configuration.networkSampleRate
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
