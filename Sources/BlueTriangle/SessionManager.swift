//
//  SessionManager.swift
//  
//
//  Created by Ashok Singh on 19/08/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

protocol SessionManagerProtocol  {
    func start(with expiry : Millisecond)
    func getSessionData() -> SessionData?
    func stop()
}


import Combine

/// A session manager responsible for managing session-related functionality in the SDK.
///
/// The `SessionManager` class is the primary component for handling session lifecycle events,
/// such as starting, stopping, and tracking session durations. It serves as the foundation
/// for session management when the SDK is in **enabled mode** and actively tracking user activity.
///
/// - Responsibilities:
///   - Manages session lifecycle events (start, stop, and expiry).
///
/// - Note: This class is used when `enableAllTracking` is true, ensuring the SDK operates in
///         full functionality mode.

class SessionManager : SessionManagerProtocol{
    
    private var expirationDurationInMS: Millisecond = 30 * 60 * 1000
    private let lock = NSLock()
    private let sessionStore = SessionStore()
    private var cancellables = Set<AnyCancellable>()
    private var currentConfigSubscription: AnyCancellable?
    private let queue = DispatchQueue(label: "com.bluetriangle.remote", qos: .userInitiated, autoreleaseFrequency: .workItem)
    private var currentSession : SessionData?

    private let configRepo: BTTConfigurationRepo
    private let updater: BTTConfigurationUpdater
    private let configSyncer: BTTStoredConfigSyncer
    private let logger: Logging
    private var foregroundObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?
    
    init(_ logger: Logging,
         _ configRepo : BTTConfigurationRepo,
         _ updater : BTTConfigurationUpdater,
         _ configSyncer : BTTStoredConfigSyncer) {
        
        self.logger = logger
        self.configRepo = configRepo
        self.updater = updater
        self.configSyncer = configSyncer
    }

    public func start(with expiry : Millisecond){
        self.expirationDurationInMS = expiry
        self.resisterObserver()
    }
    
    public func stop(){
        self.removeConfigObserver()
        self.sessionStore.removeSessionData()
        self.currentSession = nil
    }
    
    private func resisterObserver() {
#if os(iOS)
        foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { notification in
            self.appOffScreen()
        }
        
        backgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { notification in
            self.onLaunch()
        }
#endif
        self.observeRemoteConfig()
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
    
    private func invalidateSession() -> SessionData{
       
        var hasExpired = sessionStore.isExpired()
        
        if CommandLine.arguments.contains(Constants.NEW_SESSION_ON_LAUNCH_ARGUMENT) {
            
            if let currentSession = self.currentSession, !hasExpired{
                return currentSession
            }
            
            hasExpired = true
        }
        
        if hasExpired {
            let session = SessionData(expiration: expiryDuration())
            session.isNewSession = true
            currentSession = session
            syncStoredConfigToSessionAndApply()
            sessionStore.saveSession(session)
            logger.info("BlueTriangle:SessionManager: New session \(session.sessionID) has been created")
            
            return session
        }
        else{
            
            guard let session = currentSession else {
                let session = sessionStore.retrieveSessionData()
                session!.isNewSession = false
                currentSession = session
                syncStoredConfigToSessionAndApply()
                sessionStore.saveSession(session!)
                return session!
            }
            
            return session
        }
    }
    
    public func getSessionData() -> SessionData? {
        lock.sync {
            if let session = currentSession{
                return session
            }
            
            let updatedSession = self.invalidateSession()
            return updatedSession
        }
    }

    
    private func updateSession(){
        let seesion = self.invalidateSession()
        BlueTriangle.updateSession(seesion)
    }
    
    private func expiryDuration()-> Millisecond {
        let expiry = Int64(Date().timeIntervalSince1970) * 1000 + expirationDurationInMS
        return expiry
    }
}

extension SessionManager {
    
    private func observeRemoteConfig(){
        configRepo.$currentConfig
            .dropFirst()
            .sink { [weak self] changedConfig in
                    self?.updateConfigurationOnChange()
            }.store(in: &cancellables)
    }
    
    private func updateRemoteConfig(){
        queue.async { [weak self] in
            if let isForcedUpdate = self?.currentSession?.isNewSession {
                self?.updater.update(isForcedUpdate) {}
            }
        }
    }

    private func updateConfigurationOnChange(){
        self.syncStoredConfigToSessionAndApply()
        BlueTriangle.updateCaptureRequests()
        configSyncer.updateAndApplySDKState()
    }

    private func syncStoredConfigToSessionAndApply(){
                
        if let session = currentSession {
            if session.isNewSession{
                configSyncer.syncConfigurationFromStorage()
                session.networkSampleRate = BlueTriangle.configuration.networkSampleRate
                session.shouldNetworkCapture =  .random(probability: BlueTriangle.configuration.networkSampleRate)
                session.ignoreViewControllers = BlueTriangle.configuration.ignoreViewControllers
                sessionStore.saveSession(session)
            }else{
                BlueTriangle.updateNetworkSampleRate(session.networkSampleRate)
                BlueTriangle.updateIgnoreVcs(session.ignoreViewControllers)
            }
        }
    }
}

extension SessionManager {
    
    private func removeConfigObserver(){
        if let observer = foregroundObserver {
#if os(iOS)
             NotificationCenter.default.removeObserver(observer)
#endif
            foregroundObserver = nil
        }
        
        if let observer = backgroundObserver {
#if os(iOS)
             NotificationCenter.default.removeObserver(observer)
#endif
            backgroundObserver = nil
        }
        
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
        
        cancellables.removeAll()
    }
}
