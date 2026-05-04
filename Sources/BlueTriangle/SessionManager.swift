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
    private var didBecomeActiveObserver: NSObjectProtocol?
    private var finishLaunchObserver: NSObjectProtocol?
    private var willTerminateObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?
    private var orientationObserver: NSObjectProtocol?
    private var keyboardShowObserver: NSObjectProtocol?
    private var keyboardHideObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?
    
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
                logger.info("BlueTriangle:SessionManager: Current session \(session?.sessionID ?? 0)")
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
    
    private func syncStoredConfigToSessionAndApply() {
        if let session = currentSession {
            if session.isNewSession {
                configSyncer.syncConfigurationFromStorage()
                session.networkSampleRate = BlueTriangle.configuration.networkSampleRate
                session.enableScreenTracking = BlueTriangle.configuration.enableScreenTracking
                session.enableGrouping = BlueTriangle.configuration.enableGrouping
                session.groupingIdleTime = BlueTriangle.configuration.groupingIdleTime
                session.shouldNetworkCapture = .random(probability: BlueTriangle.configuration.networkSampleRate)
                session.ignoreViewControllers = BlueTriangle.configuration.ignoreViewControllers
                session.enableCrashTracking = BlueTriangle.configuration.crashTracking == .nsException
                session.enableANRTracking = BlueTriangle.configuration.ANRMonitoring
                session.enableMemoryWarning = BlueTriangle.configuration.enableMemoryWarning
                session.enableLaunchTime = BlueTriangle.configuration.enableLaunchTime
                session.enableWebViewStitching = BlueTriangle.configuration.enableWebViewStitching
                session.enableNetworkStateTracking = BlueTriangle.configuration.enableTrackingNetworkState
                session.enableGroupingTapDetection = BlueTriangle.configuration.enableGroupingTapDetection
                session.checkoutTrackingEnabled = BlueTriangle.configuration.checkoutTrackingEnabled
                session.checkoutClassName = BlueTriangle.configuration.checkoutClassName
                session.checkoutURL = BlueTriangle.configuration.checkoutURL
                session.checkoutAmount = BlueTriangle.configuration.checkoutAmount
                session.checkoutCartCount = BlueTriangle.configuration.checkoutCartCount
                session.checkoutCartCountCheckout = BlueTriangle.configuration.checkoutCartCountCheckout
                session.checkoutOrderNumber = BlueTriangle.configuration.checkoutOrderNumber
                session.checkoutTimeValue = BlueTriangle.configuration.checkoutTimeValue
                session.ignoreBreadcrumbs = BlueTriangle.configuration.ignoreBreadcrumbs
                session.enableBreadcrumbs = BlueTriangle.configuration.enableBreadcrumbs
                session.configKey = BlueTriangle.configuration.configKey
                sessionStore.saveSession(session)
            } else {
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
                BlueTriangle.updateCheckoutTracking(session.checkoutTrackingEnabled)
                BlueTriangle.updateCheckoutClassNames(session.checkoutClassName)
                BlueTriangle.updateCheckoutURL(session.checkoutURL)
                BlueTriangle.updateCheckoutAmount(session.checkoutAmount)
                BlueTriangle.updateCheckoutCartCount(session.checkoutCartCount)
                BlueTriangle.updateCheckoutCartCountCheckout(session.checkoutCartCountCheckout)
                BlueTriangle.updateCheckoutOrderNumber(session.checkoutOrderNumber)
                BlueTriangle.updateCheckoutTimeValue(session.checkoutTimeValue)
                BlueTriangle.updateIgnoreBreadcrumbs(session.ignoreBreadcrumbs)
                BlueTriangle.updateEnableBreadcrumbs(session.enableBreadcrumbs)
                BlueTriangle.updateConfigKey(session.configKey)
                sessionStore.saveSession(session)
            }
        }
    }
}

extension SessionManager {
    
    private func resisterObserver() {
#if os(iOS)
        terminateObserver = NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { notification in
            NSLog("BTT Log :  UIApplication.willTerminateNotification")
        }
        
        finishLaunchObserver = NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: nil) { notification in
            BlueTriangle.collectBreadcrumb(AppLifecycleEvent(event: Constants.Breadcrums.AppLifeCycle.didFinishLaunch))
        }
        
        didBecomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { notification in
            BlueTriangle.collectBreadcrumb(AppLifecycleEvent(event: Constants.Breadcrums.AppLifeCycle.didBecomeActive))
        }
        
        willTerminateObserver = NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { notification in
            BlueTriangle.collectBreadcrumb(AppLifecycleEvent(event: Constants.Breadcrums.AppLifeCycle.willTerminate))
        }
        
        backgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { notification in
            self.appOffScreen()
            BlueTriangle.collectBreadcrumb(AppLifecycleEvent(event: Constants.Breadcrums.AppLifeCycle.didEnterBackground))
        }
        
        foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { notification in
            self.onLaunch()
            BlueTriangle.collectBreadcrumb(AppLifecycleEvent(event: Constants.Breadcrums.AppLifeCycle.willEnterForeground))
        }
        
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: nil
        ) { _ in
            let orientation = UIDevice.current.orientation
            var orientationString = Constants.Breadcrums.Orientation.unknown
            switch orientation {
            case .portrait, .portraitUpsideDown:
                orientationString = Constants.Breadcrums.Orientation.portrait
            case .landscapeLeft, .landscapeRight:
                orientationString = Constants.Breadcrums.Orientation.landscape
            default:
                break
            }
            BlueTriangle.collectBreadcrumb(AppSystemEvent(event: orientationString, eventType: Constants.Breadcrums.Orientation.className))
        }
        
        keyboardShowObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: nil
        ) { _ in
            BlueTriangle.collectBreadcrumb(AppSystemEvent(event: Constants.Breadcrums.Keyboard.shown, eventType: Constants.Breadcrums.Keyboard.className))
        }
        
        keyboardHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: nil
        ) { _ in
            BlueTriangle.collectBreadcrumb(AppSystemEvent(event: Constants.Breadcrums.Keyboard.hidden, eventType: Constants.Breadcrums.Keyboard.className))
        }
#endif
        self.observeRemoteConfig()
        self.updateSession()
    }
    
    private func removeConfigObserver(){
        
        if let observer = orientationObserver {
#if os(iOS)
            NotificationCenter.default.removeObserver(observer)
#endif
            orientationObserver = nil
        }
        
        if let observer = keyboardShowObserver {
#if os(iOS)
            NotificationCenter.default.removeObserver(observer)
#endif
            keyboardShowObserver = nil
        }
        
        if let observer = keyboardHideObserver {
#if os(iOS)
            NotificationCenter.default.removeObserver(observer)
#endif
            keyboardHideObserver = nil
        }
        
        if let observer = finishLaunchObserver {
#if os(iOS)
            NotificationCenter.default.removeObserver(observer)
#endif
            finishLaunchObserver = nil
        }
        
        if let observer = didBecomeActiveObserver {
#if os(iOS)
            NotificationCenter.default.removeObserver(observer)
#endif
            didBecomeActiveObserver = nil
        }
        
        if let observer = willTerminateObserver {
#if os(iOS)
            NotificationCenter.default.removeObserver(observer)
#endif
            willTerminateObserver = nil
        }
        
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
