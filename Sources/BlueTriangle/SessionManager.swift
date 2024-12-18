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

import Combine

class SessionManager {
   
    private var expirationDurationInMS: Millisecond = 30 * 60 * 1000
    private let lock = NSLock()
    private let sessionStore = SessionStore()
    private var cancellables = Set<AnyCancellable>()
    private let queue = DispatchQueue(label: "com.bluetriangle.remote", qos: .userInitiated, autoreleaseFrequency: .workItem)
    private var currentSession : SessionData?

    private let configFetcher: BTTConfigurationFetcher
    private let configRepo: BTTConfigurationRepo
    private let logger: Logging
    private let configAck: RemoteConfigAckReporter
    private let updater: BTTConfigurationUpdater
    
    init(_ logger: Logging,
         _ configRepo : BTTConfigurationRepo,
         _ fetcher : BTTConfigurationFetcher,
         _ configAck : RemoteConfigAckReporter,
         _ updater : BTTConfigurationUpdater) {
        
        self.logger = logger
        self.configRepo = configRepo
        self.configFetcher = fetcher
        self.configAck = configAck
        self.updater = updater
    }
    
    public func start(with expiry : Millisecond){
        self.expirationDurationInMS = expiry
        
#if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { notification in
            self.appOffScreen()
        }

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { notification in
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
            
            if let currentSession = self.currentSession{
                return currentSession
            }
            
            hasExpired = true
        }
        
        if hasExpired {
            let session = SessionData(expiration: expiryDuration())
            session.isNewSession = true
            currentSession = session
            reloadSession()
            sessionStore.saveSession(session)
            logger.info("BlueTriangle:SessionManager: New session \(session.sessionID) has been created")
            
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
    
    public func getSessionData() -> SessionData {
        lock.sync {
            let updatedSession = self.invalidateSession()
            return updatedSession
        }
    }
    
    private func updateSession(){
        BlueTriangle.updateSession(getSessionData())
    }
    
    private func expiryDuration()-> Millisecond {
        let expiry = Int64(Date().timeIntervalSince1970) * 1000 + expirationDurationInMS
        return expiry
    }
}

extension SessionManager {
    
    private func observeRemoteConfig(){
        
        configRepo.$currentConfig
            .sink { changedConfig in
                if let _ = changedConfig{
                    self.reloadSession()
                    BlueTriangle.refreshCaptureRequests()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateRemoteConfig(){
        queue.async { [weak self] in
            if let isNewSession = self?.currentSession?.isNewSession {
                self?.updater.update(isNewSession) {}
            }
        }
    }
    
    private func reloadSession(){
                
        if let session = currentSession {
            if session.isNewSession{
                self.syncConfigurationOnNewSession()
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
    
    private func syncConfigurationOnNewSession(){
        self.syncNetworkSampleRate()
        self.syncIgnoreViewControllers()
    }
    
    private func syncNetworkSampleRate(){
        
        do{
            if CommandLine.arguments.contains(Constants.FULL_SAMPLE_RATE_ARGUMENT) {
                BlueTriangle.updateNetworkSampleRate(1.0)
                return
            }
            
            if let config = try configRepo.get(){
                
                let sampleRate = config.networkSampleRateSDK ?? configRepo.defaultConfig.networkSampleRateSDK
                
                if let rate = sampleRate{
                    if rate == 0 {
                        BlueTriangle.updateNetworkSampleRate(0.0)
                    }else{
                        BlueTriangle.updateNetworkSampleRate(Double(rate) / 100.0)
                    }
                    
                    logger.info("BlueTriangle:SessionManager: Applied networkSampleRate - \(rate) %")
                }
            }
        }
        catch {
            logger.error("BlueTriangle:SessionManager: Failed to retrieve remote configuration from the repository - \(error)")
        }
    }
    
    private func syncIgnoreViewControllers(){
        do{
            if let config = try configRepo.get(){
                
                let ignoreScreens = config.ignoreScreens ?? configRepo.defaultConfig.ignoreScreens
                
                if let ignoreVcs = ignoreScreens{
                                       
                    var unianOfIgnoreScreens = Set(ignoreVcs)
                    
                    if let defaultScreens = configRepo.defaultConfig.ignoreScreens{
                        unianOfIgnoreScreens = unianOfIgnoreScreens.union(Set(defaultScreens))
                    }
                   
                    BlueTriangle.updateIgnoreVcs(unianOfIgnoreScreens)
                    
                    logger.info("BlueTriangle:SessionManager: Applied ignore Vcs - \(BlueTriangle.configuration.ignoreViewControllers)")
                }
            }
        }
        catch {
            logger.error("BlueTriangle:SessionManager: Failed to retrieve remote configuration from the repository - \(error)")
        }
    }
}
