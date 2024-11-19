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
   
    private let lock = NSLock()
    private var logger: Logging?
    private var expirationDurationInMS: Millisecond = 30 * 60 * 1000
    private let  sessionStore = SessionStore()
    private var currentSession : SessionData?
   
    private let queue = DispatchQueue(label: "com.bluetriangle.remote", qos: .userInitiated, autoreleaseFrequency: .workItem)
    private let configFetcher: BTTConfigurationFetcher
    private let configRepo: BTTConfigurationRepo
    private var cancellables = Set<AnyCancellable>()
    lazy var updater = BTTConfigurationUpdater(configFetcher: configFetcher, configRepo: configRepo, logger: logger)
    
    init(_ configRepo : BTTConfigurationRepo = BTTConfigurationRepo(BTTRemoteConfig.defaultConfig),_ fetcher : BTTConfigurationFetcher =  BTTConfigurationFetcher()) {
        self.configRepo = configRepo
        self.configFetcher = fetcher
    }
    
    public func start(with  expiry : Millisecond, logger: Logging){
        
        self.logger = logger
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
    
    public func getSessionData() -> SessionData {
        lock.sync {
            let updatedSession = self.invalidateSession()
            return updatedSession
        }
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
        
    private func observeRemoteConfig(){

        configRepo.$currentConfig
            .sink { changedConfig in
                if let config = changedConfig{
                    self.logger?.info("Remote config has changed")
                    self.reloadSession()
                    BlueTriangle.refreshCaptureRequests()
                    print("Current config changed: \(String(describing: config.networkSampleRateSDK))")
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateSession(){
        BlueTriangle.updateSession(getSessionData())
    }
    
    private func updateRemoteConfig(){
        queue.async { [weak self] in
            if let isNewSession = self?.currentSession?.isNewSession {
                self?.updater.update(isNewSession) {
                    self?.logger?.info("updated remote config")
                }
            }
        }
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
            logger?.info("New session \(session.sessionID) has created")
            
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
                self.syncConfiguration()
                session.networkSampleRate = BlueTriangle.configuration.networkSampleRate
                session.shouldNetworkCapture =  .random(probability: BlueTriangle.configuration.networkSampleRate)
                sessionStore.saveSession(session)
                logger?.info("Sync new session remote config with configuration \(BlueTriangle.configuration.networkSampleRate)")
            }else{
                BlueTriangle.updateNetworkSampleRate(session.networkSampleRate)
                logger?.info("Sync old session remote config with configuration \(BlueTriangle.configuration.networkSampleRate)")
            }
        }
    }
    
    private func syncConfiguration(){
        do{
            if CommandLine.arguments.contains(Constants.FULL_SAMPLE_RATE_ARGUMENT) {
                BlueTriangle.updateNetworkSampleRate(1.0)
                return
            }
            
            if let config = try configRepo.get(){
                if let rate = config.networkSampleRateSDK{
                    BlueTriangle.updateNetworkSampleRate(Double(rate) / 100.0)
                }
            }
        }
        catch {
            logger?.error("Error syncing remote config: \(error)")
        }
    }
    
    private func expiryDuration()-> Millisecond {
        let expiry = Int64(Date().timeIntervalSince1970) * 1000 + expirationDurationInMS
        return expiry
    }
}

