//
//  DisableModeSessionManager.swift
//  
//
//  Created by Ashok Singh on 13/01/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

import Combine

/// A specialized session manager for handling the SDK's behavior in disabled mode.
///
/// This class is responsible for managing session-related functionality when the SDK
/// is in **disabled mode**. In this mode, the SDK's features are turned off, and only
/// the essential components, such as the **Remote Configuration Updater**, remain active.
///
/// - Responsibilities:
///   - Ensures minimal overhead while maintaining the ability to monitor the remote configuration.
///
/// - Note: This session manager is used exclusively when `enableAllTracking` is false.
///
class DisableModeSessionManager : SessionManagerProtocol {
    
    private var expirationDurationInMS: Millisecond = 30 * 60 * 1000
    private let lock = NSLock()
    private var cancellables = Set<AnyCancellable>()
    private let queue = DispatchQueue(label: "com.bluetriangle.remote", qos: .userInitiated, autoreleaseFrequency: .workItem)
    
    private let configRepo: BTTConfigurationRepo
    private let logger: Logging
    private let updater: BTTConfigurationUpdater
    private let configSyncer: BTTStoredConfigSyncer
    private var isUpdatingConfig = false
    private var foregroundObserver: NSObjectProtocol?
    
    private var isObserverRegistered: Bool {
        cancellables.isEmpty == false
    }
    
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
        removeConfigObserver()
    }
     
     private func resisterObserver() {
 #if os(iOS)
         foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { notification in
             self.onLaunch()
         }
 #endif
         self.observeRemoteConfig()
     }
     
    func getSessionData() -> SessionData? {
        return nil
    }
    
    private func onLaunch(){
        self.updateRemoteConfig()
    }
 }

 extension DisableModeSessionManager {
     
     private func observeRemoteConfig(){
         configRepo.$currentConfig
             .dropFirst()
             .sink { [weak self]  changedConfig in
                 self?.updateConfigurationOnChange()
             }
             .store(in: &cancellables)
     }
     
     private func updateRemoteConfig(){
         queue.async { [weak self] in
             self?.updater.update(true) {}
         }
     }
     
     private func updateConfigurationOnChange(){
         configSyncer.updateAndApplySDKState()
     }
}

extension DisableModeSessionManager {
    
     private func removeConfigObserver(){
        
         if let observer = foregroundObserver {
#if os(iOS)
             NotificationCenter.default.removeObserver(observer)
#endif
             foregroundObserver = nil
         }
         
         self.cancellables.forEach { cancellable in
             cancellable.cancel()
         }
         
         cancellables.removeAll()
     }
}
