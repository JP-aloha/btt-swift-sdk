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
}

class BTTConfigurationRepo : ConfigurationRepo{
    
    private let key = Constants.BTT_BUFFER_REMOTE_CONFIG_KEY
    private let queue = DispatchQueue(label: "com.bluetriangle.configurationRepo", attributes: .concurrent)
    private let defaultConfig : BTTRemoteConfig
    private let lock = NSLock()

    @Published private(set) var currentConfig: BTTSavedRemoteConfig?
    
    init(_ defaultConfig : BTTRemoteConfig){
        self.defaultConfig = defaultConfig
        self.loadConfig()
    }
    
    func get() throws -> BTTSavedRemoteConfig? {
        
        if let data = UserDefaults.standard.data(forKey: key) {
            return try JSONDecoder().decode(BTTSavedRemoteConfig.self, from: data)
        }
        
        return nil
    }
    
    func save(_ config: BTTRemoteConfig) throws {
        let newConfig = BTTSavedRemoteConfig(networkSampleRateSDK: config.networkSampleRateSDK,
                                             dateSaved: Date().timeIntervalSince1970.milliseconds)
        
        try queue.sync(flags: .barrier) {
            do {
                let data = try JSONEncoder().encode(newConfig)
                UserDefaults.standard.set(data, forKey: key)
                
                print("Save data")

                if newConfig != currentConfig {
                    self.currentConfig = newConfig
                    print("Save changed")
                }
            }
        }
    }
    
    private func loadConfig(){
        do{
            guard let config = try get() else {
                print("Save default")
                try self.save(defaultConfig)
                return
            }

            self.currentConfig = config
            print("Load changed")
        }
        catch{
            print("Fail to load remote changed")
        }
    }
}
