//
//  BTTConfigurationRepo.swift
//  
//
//  Created by Ashok Singh on 05/09/24.
//

import Foundation

protocol ConfigurationRepo {
    func get() -> BTTSavedRemoteConfig?
    func save(_ config: BTTRemoteConfig)
    func clear()
}

class BTTConfigurationRepo : ConfigurationRepo{
    
    private let SavedRemoteConfigKey = Constants.BTT_SAVED_REMOTE_CONFIG_KEY
    private let userDefault = UserDefaults.standard
    
    
    func get() -> BTTSavedRemoteConfig? {
        if let data = userDefault.data(forKey: SavedRemoteConfigKey) {
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
    
    func save(_ config: BTTRemoteConfig) {
        let newConfig = BTTSavedRemoteConfig(errorSamplePercent: config.errorSamplePercent,
                                             wcdSamplePercent: config.wcdSamplePercent,
                                             dateSaved: Date().timeIntervalSince1970.milliseconds)
        do {
            let data = try JSONEncoder().encode(newConfig)
            userDefault.set(data, forKey: SavedRemoteConfigKey)
            userDefault.synchronize()
        } catch {
            print("Failed to encode and save config to UserDefaults: \(error)")
        }
    }
    
    func clear(){
        userDefault.removeObject(forKey: SavedRemoteConfigKey)
        userDefault.synchronize()
    }
}
