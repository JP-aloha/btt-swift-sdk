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

class DisableModeSessionManager : SessionManagerProtocol {

     private var expirationDurationInMS: Millisecond = 30 * 60 * 1000
     private let lock = NSLock()
     private var cancellables = Set<AnyCancellable>()
     private let queue = DispatchQueue(label: "com.bluetriangle.remote", qos: .userInitiated, autoreleaseFrequency: .workItem)

     private let configRepo: BTTConfigurationRepo
     private let logger: Logging
     private let updater: BTTConfigurationUpdater
     private var isUpdatingConfig = false
    private var foregroundObserver: NSObjectProtocol?
     
    private var isObserverRegistered: Bool {
        cancellables.isEmpty == false
    }
    
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
         foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { notification in
             self.onLaunch()
         }
 #endif
         self.observeRemoteConfig()
     }
     
    func getSessionData() -> SessionData {
        self.reloadConfig()
        let sessionData = SessionData.init(expiration: 0)
        return sessionData
    }
    
    private func onLaunch(){
        self.updateRemoteConfig()
    }
    
    private func removeConfigObserver(){
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
            foregroundObserver = nil
        }
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
        cancellables.removeAll()
    }
 }

 extension DisableModeSessionManager {
     
     private func observeRemoteConfig(){
         
         configRepo.$currentConfig
             .dropFirst()
             .sink { [weak self]  changedConfig in
                 if let _ = changedConfig{
                     self?.reloadConfig()
                     if BlueTriangle.initialized {
                         BlueTriangle.configureSDK()
                     }
                 }
             }
             .store(in: &cancellables)
         
         print("cancellables : \(cancellables.count)")
     }
     
     private func updateRemoteConfig(){
         queue.async { [weak self] in
             self?.updater.update(true) {}
         }
     }
     
     private func reloadConfig(){
         self.syncConfigurationOnNewSession()
     }
     
     private func syncConfigurationOnNewSession(){
         self.syncSDKEnableStatus()
     }
     
     private func syncSDKEnableStatus(){
         do{
             if let config = try configRepo.get(){
                 BlueTriangle.isEnableSDK = config.isSDKEnabled ?? true
                 logger.info("BlueTriangle:DisableModeSessionManager: Configure SDK MODE - \(BlueTriangle.isEnableSDK ? "true": "false")")
             }
         }
         catch {
             logger.error("BlueTriangle:DisableModeSessionManager: Failed to retrieve remote configuration from the repository - \(error)")
         }
     }
}
