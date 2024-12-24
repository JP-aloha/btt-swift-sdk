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
        
        let newConfig = BTTSavedRemoteConfig(networkSampleRateSDK: config.networkSampleRateSDK,
                                             enableRemoteConfigAck : config.enableRemoteConfigAck,
                                             ignoreScreens: config.ignoreScreens,
                                             dateSaved: Date().timeIntervalSince1970.milliseconds)
        
        try queue.sync(flags: .barrier) {
            do {
                let data = try JSONEncoder().encode(newConfig)
                UserDefaults.standard.set(data, forKey: key())
               
                if hasChange(config){
                    self.currentConfig = newConfig
                }
            }
        }
    }
    
    func hasChange( _ config : BTTRemoteConfig) -> Bool{
        
        let newConfig = BTTSavedRemoteConfig(networkSampleRateSDK: config.networkSampleRateSDK,
                                             enableRemoteConfigAck : config.enableRemoteConfigAck,
                                             ignoreScreens: config.ignoreScreens,
                                             dateSaved: Date().timeIntervalSince1970.milliseconds)
        
        if let current = currentConfig, newConfig == current{
            return false
        }else{
            return true
        }
    }
}

extension BTTConfigurationRepo{
    
    private func loadConfig(){
        do{
            guard let config = try get() else {
                self.currentConfig = defaultConfig
                return
            }
            
            self.currentConfig = config
        }
        catch{
            print("Failed to load remote")
        }
    }
}
