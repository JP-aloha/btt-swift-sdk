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
    func synchronize()
}

class BTTConfigurationRepo : ConfigurationRepo{
    
    private let userDefault = UserDefaults.standard
    private let key = Constants.BTT_BUFFER_REMOTE_CONFIG_KEY
    
    func get() -> BTTSavedRemoteConfig? {
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
    
    func save(_ config: BTTRemoteConfig) {
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
    
    func synchronize(){
        if let config = self.get(){
            let rate = Double(config.wcdSamplePercent) / 100.0
            BlueTriangle.updateNetworkSampleRate(rate)
        }
    }
}
