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

protocol SessionManagerProtocol : Sendable {
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

final class SessionManager : SessionManagerProtocol, @unchecked Sendable {
    
    private var expirationDurationInMS: Millisecond = 30 * 60 * 1000
    private let lock = NSLock()
    private let sessionStore = SessionStore()
    private var cancellables = Set<AnyCancellable>()
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
    
    private func setCurrentSession(_ session : SessionData?){
        lock.sync {
            self.currentSession = session
        }
    }
    
    private func getCurrentSession() -> SessionData? {
        lock.sync {
            return self.currentSession
        }
    }

    public func start(with expiry : Millisecond){
        self.expirationDurationInMS = expiry
        self.onLaunch()
        self.resisterObserver()
    }
    
    public func stop(){
        self.removeConfigObserver()
        self.sessionStore.removeSessionData()
        self.setCurrentSession(nil)
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
        if let session = getCurrentSession() {
            session.expiration = expiryDuration()
            session.isNewSession = false
            self.setCurrentSession(session)
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
            if let currentSession = self.getCurrentSession(), !hasExpired{
                return currentSession
            }
            hasExpired = true
        }
        
        if hasExpired {
            let session = SessionData(expiration: expiryDuration())
            session.isNewSession = true
            self.setCurrentSession(session)
            syncStoredConfigToSessionAndApply()
            sessionStore.saveSession(session)
            logger.info("BlueTriangle:SessionManager: New session \(session.sessionID) has been created")
            
            return session
        } else {
            guard let session = getCurrentSession() else {
                let session = sessionStore.retrieveSessionData()
                session!.isNewSession = false
                self.setCurrentSession(session)
                syncStoredConfigToSessionAndApply()
                sessionStore.saveSession(session!)
                logger.info("BlueTriangle:SessionManager: Current session \(session?.sessionID ?? 0)")
                return session!
            }
            
            return session
        }
    }
    
    public func getSessionData() -> SessionData? {
        if let session = getCurrentSession(){
            return session
        }
        
        let updatedSession = self.invalidateSession()
        return updatedSession
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

    private func updateConfigurationOnChange() {
        Task {
            self.syncStoredConfigToSessionAndApply()
            await BlueTriangle.updateCaptureRequests()
            await BlueTriangle.updateGroupedViewCaptureRequest()
            await configSyncer.updateAndApplySDKState()
        }
    }

    private func syncStoredConfigToSessionAndApply() {
        if let session = currentSession {
            if session.isNewSession {
                configSyncer.syncConfigurationFromStorage()
                session.networkSampleRate = BlueTriangle.configuration.networkSampleRate
                session.enableScreenTracking = BlueTriangle.configuration.enableScreenTracking
                session.groupedViewSampleRate = BlueTriangle.configuration.groupedViewSampleRate
                session.enableGrouping = BlueTriangle.configuration.enableGrouping
                session.groupingIdleTime = BlueTriangle.configuration.groupingIdleTime
                session.shouldNetworkCapture = .random(probability: BlueTriangle.configuration.networkSampleRate)
                session.shouldGroupedViewCapture = .random(probability: BlueTriangle.configuration.groupedViewSampleRate)
                session.ignoreViewControllers = BlueTriangle.configuration.ignoreViewControllers
                session.enableCrashTracking = BlueTriangle.configuration.crashTracking == .nsException
                session.enableANRTracking = BlueTriangle.configuration.ANRMonitoring
                session.enableMemoryWarning = BlueTriangle.configuration.enableMemoryWarning
                session.enableLaunchTime = BlueTriangle.configuration.enableLaunchTime
                session.enableWebViewStitching = BlueTriangle.configuration.enableWebViewStitching
                session.enableNetworkStateTracking = BlueTriangle.configuration.enableTrackingNetworkState
                session.enableGroupingTapDetection = BlueTriangle.configuration.enableGroupingTapDetection
                sessionStore.saveSession(session)
            } else {
                BlueTriangle.updateGroupedViewSampleRate(session.groupedViewSampleRate)
                BlueTriangle.updateGrouping(session.enableGrouping, idleTime: session.groupingIdleTime)
                BlueTriangle.updateScreenTracking(session.enableScreenTracking)
                BlueTriangle.updateNetworkSampleRate(session.networkSampleRate)
                BlueTriangle.updateIgnoreVcs(session.ignoreViewControllers)
                BlueTriangle.updateLaunchTime(session.enableLaunchTime)
                BlueTriangle.updateTrackingNetworkState(session.enableNetworkStateTracking)
                BlueTriangle.updateCrashTracking(session.enableCrashTracking)
                BlueTriangle.updateAnrMonitoring(session.enableANRTracking)
                BlueTriangle.updateMemoryWarning(session.enableMemoryWarning)
                BlueTriangle.updateWebViewStitching(session.enableWebViewStitching)
                BlueTriangle.updateGroupingTapDetection(session.enableGroupingTapDetection)
                sessionStore.saveSession(session)
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
