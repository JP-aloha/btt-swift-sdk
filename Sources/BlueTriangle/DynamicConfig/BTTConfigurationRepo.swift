//
//  BTTConfigurationRepo.swift
//  
//
//  Created by Ashok Singh on 05/09/24.
//

import Foundation

protocol ConfigurationRepo {
    func get(_ key : String) -> BTTSavedRemoteConfig?
    func save(_ config: BTTRemoteConfig,  key : String)
    func refreshConfiguration()
}

class BTTConfigurationRepo : ConfigurationRepo{
    
    private let userDefault = UserDefaults.standard
    
    
    func get(_ key : String) -> BTTSavedRemoteConfig? {
        if let data = userDefault.data(forKey: key) {
            do {
                let savedConfig = try JSONDecoder().decode(BTTSavedRemoteConfig.self, from: data)
                return savedConfig
            } catch {
                print("Failed to decode config from UserDefaults: \(error)")
                return nil
            }
        }
        return nil
    }
    
    func save(_ config: BTTRemoteConfig,  key : String) {
        let newConfig = BTTSavedRemoteConfig(errorSamplePercent: config.errorSamplePercent,
                                             wcdSamplePercent: config.wcdSamplePercent,
                                             dateSaved: Date().timeIntervalSince1970.milliseconds)
        do {
            let data = try JSONEncoder().encode(newConfig)
            userDefault.set(data, forKey: key)
            userDefault.synchronize()
        } catch {
            print("Failed to encode and save config to UserDefaults: \(error)")
        }
    }
    
    func refreshConfiguration(){
        if let currentConfig = self.get(Constants.BTT_CURRENT_REMOTE_CONFIG_KEY){
            let networkSampleRate = Double(currentConfig.wcdSamplePercent) / 100.0
            BlueTriangle.configuration.networkSampleRate = networkSampleRate
        }
    }
}
