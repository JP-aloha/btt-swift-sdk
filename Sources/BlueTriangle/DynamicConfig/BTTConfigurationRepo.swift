//
//  BTTConfigurationRepo.swift
//
//
//  Created by Ashok Singh on 05/09/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

protocol ConfigurationRepo {
    func get() throws -> BTTSavedRemoteConfig?
    func save(_ config: BTTRemoteConfig) throws
    func hasChange( _ config : BTTRemoteConfig) -> Bool
}

class BTTConfigurationRepo : ConfigurationRepo{
    
    private let queue = DispatchQueue(label: "com.bluetriangle.configurationRepo", attributes: .concurrent)
    private let lock = NSLock()
    private(set) var defaultConfig : BTTSavedRemoteConfig
    @Published private(set) var currentConfig: BTTSavedRemoteConfig?
    private func key() -> String { return BlueTriangle.configuration.siteID }
    
    init(_ defaultConfig : BTTSavedRemoteConfig){
        self.defaultConfig = defaultConfig
        self.loadConfig()
    }
    
    func get() throws -> BTTSavedRemoteConfig? {
        
        if let data = UserDefaults.standard.data(forKey: key()) {
            let config = try JSONDecoder().decode(BTTSavedRemoteConfig.self, from: data)
            return config
        }
        
        return nil
    }
    
    func save(_ config: BTTRemoteConfig) throws {
        
        let newConfig = BTTSavedRemoteConfig(
              networkSampleRateSDK: config.networkSampleRateSDK,
              enableRemoteConfigAck: config.enableRemoteConfigAck,
              enableAllTracking: config.enableAllTracking,
              enableScreenTracking: config.enableScreenTracking,
              enableGrouping: config.enableGrouping,
              groupingIdleTime: config.groupingIdleTime,
              ignoreScreens: config.ignoreScreens,
              enableCrashTracking: config.enableCrashTracking,
              enableANRTracking: config.enableANRTracking,
              enableMemoryWarning: config.enableMemoryWarning,
              enableLaunchTime: config.enableLaunchTime,
              enableWebViewStitching: config.enableWebViewStitching,
              enableNetworkStateTracking: config.enableNetworkStateTracking,
              enableGroupingTapDetection: config.enableGroupingTapDetection,
              checkoutTrackingEnabled: config.checkoutTrackingEnabled,
              checkoutClassName: config.checkoutClassName,
              checkoutURL: config.checkoutURL,
              checkoutAmount: config.checkoutAmount,
              checkoutCartCount: config.checkoutCartCount,
              checkoutCartCountCheckout: config.checkoutCartCountCheckout,
              checkoutOrderNumber: config.checkoutOrderNumber,
              checkoutTimeValue: config.checkoutTimeValue,
              dateSaved: Date().timeIntervalSince1970.milliseconds
          )
        
        try queue.sync(flags: .barrier) {
            do {
                let data = try JSONEncoder().encode(newConfig)
                UserDefaults.standard.set(data, forKey: key())
                self.push(newConfig)
            }
        }
    }
    
    func hasChange( _ config : BTTRemoteConfig) -> Bool{
        
        let newConfig = BTTSavedRemoteConfig(
             networkSampleRateSDK: config.networkSampleRateSDK,
             enableRemoteConfigAck: config.enableRemoteConfigAck,
             enableAllTracking: config.enableAllTracking,
             enableScreenTracking: config.enableScreenTracking,
             enableGrouping: config.enableGrouping,
             groupingIdleTime: config.groupingIdleTime,
             ignoreScreens: config.ignoreScreens,
             enableCrashTracking: config.enableCrashTracking,
             enableANRTracking: config.enableANRTracking,
             enableMemoryWarning: config.enableMemoryWarning,
             enableLaunchTime: config.enableLaunchTime,
             enableWebViewStitching: config.enableWebViewStitching,
             enableNetworkStateTracking: config.enableNetworkStateTracking,
             enableGroupingTapDetection: config.enableGroupingTapDetection,
             checkoutTrackingEnabled: config.checkoutTrackingEnabled,
             checkoutClassName: config.checkoutClassName,
             checkoutURL: config.checkoutURL,
             checkoutAmount: config.checkoutAmount,
             checkoutCartCount: config.checkoutCartCount,
             checkoutCartCountCheckout: config.checkoutCartCountCheckout,
             checkoutOrderNumber: config.checkoutOrderNumber,
             checkoutTimeValue: config.checkoutTimeValue,
             dateSaved: Date().timeIntervalSince1970.milliseconds
         )
        
        if let current = currentConfig, newConfig == current{
            return false
        }else{
            return true
        }
    }
    
    func isEnableAllTracking() -> Bool{
        var enableAllTracking = defaultConfig.enableAllTracking ?? true
        do{
            guard let value = try get()?.enableAllTracking else {
                return enableAllTracking
            }
            
            enableAllTracking = value
        }
        catch{}
        return enableAllTracking
    }
}

extension BTTConfigurationRepo{
    
    private func push(_ config : BTTSavedRemoteConfig){
        if hasChange(config){
            self.currentConfig = config
        }
    }
    
    private func loadConfig(){
        do{
            print("load remote Oserver")
            guard let config = try get() else {
                self.push(defaultConfig)
                return
            }
            
           self.push(config)
        }
        catch{
            print("Failed to load remote")
        }
    }
}
