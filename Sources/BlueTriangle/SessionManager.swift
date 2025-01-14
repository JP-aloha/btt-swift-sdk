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
    func getSessionData() -> SessionData
    func stop()
}


import Combine

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
    private let logger: Logging
    private var foregroundObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?
    
    init(_ logger: Logging,
         _ configRepo : BTTConfigurationRepo,
         _ updater : BTTConfigurationUpdater) {
        
        self.logger = logger
        self.configRepo = configRepo
        self.updater = updater
    }

    public func start(with expiry : Millisecond){
        self.expirationDurationInMS = expiry
        self.resisterObserver()
    }
    
    public func stop(){
        removeConfigObserver()
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
    
    private func removeConfigObserver(){
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
            foregroundObserver = nil
        }
        
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
            backgroundObserver = nil
        }
        
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
        
        cancellables.removeAll()
    }
}

extension SessionManager {
    
    private func observeRemoteConfig(){
        configRepo.$currentConfig
            .dropFirst()
            .sink { changedConfig in
                if let _ = changedConfig{
                    self.reloadSession()
                    print("Change Observed")
                    if BlueTriangle.initialized {
                        BlueTriangle.configureSDK()
                    }
                    BlueTriangle.refreshCaptureRequests()
                }
            }.store(in: &cancellables)
        
        print("cancellables : \(cancellables.count)")
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
            
            self.syncConfigurationEveryChange()
            
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
    
    private func syncConfigurationEveryChange(){
        self.syncSDKEnableStatus()
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
    
    private func syncSDKEnableStatus(){
        do{
            if let config = try configRepo.get(){
                BlueTriangle.isEnableSDK = config.isSDKEnabled ?? true                
                logger.info("BlueTriangle:SessionManager: Configure SDK MODE - \(BlueTriangle.isEnableSDK ? "true": "false")")
            }
        }
        catch {
            logger.error("BlueTriangle:SessionManager: Failed to retrieve remote configuration from the repository - \(error)")
        }
    }
}
