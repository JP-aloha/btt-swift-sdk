//
//  BTTConfigurationUpdater.swift
//  
//
//  Created by Ashok Singh on 05/09/24.
//

import Foundation
import Combine

protocol ConfigurationUpdater {
    func update(_ isNewSession : Bool, completion: @escaping (BTTRemoteConfig?) -> Void)
}

class BTTConfigurationUpdater : ConfigurationUpdater {
    
    private let updatePeriod: Millisecond = .hour
    private let configFetcher : ConfigurationFetcher
    private let configRepo : ConfigurationRepo
        
    init(configFetcher : ConfigurationFetcher, configRepo : ConfigurationRepo) {
        self.configFetcher = configFetcher
        self.configRepo = configRepo
    }
    
    func update(_ isNewSession : Bool, completion: @escaping (BTTRemoteConfig?) -> Void) {
        self.update(isNewSession) {
            var remoteConfig : BTTSavedRemoteConfig?
            if isNewSession {
                if let bufferConfig = self.configRepo.get(Constants.BTT_BUFFER_REMOTE_CONFIG_KEY){
                    remoteConfig = bufferConfig
                }
            }
            else{
                if let currentConfig = self.configRepo.get(Constants.BTT_CURRENT_REMOTE_CONFIG_KEY){
                    remoteConfig = currentConfig
                }
            }
            completion(remoteConfig)
        }
    }
    
    private func update(_ isNewSession : Bool, completion: @escaping () -> Void) {
        if let savedConfig = configRepo.get(Constants.BTT_CURRENT_REMOTE_CONFIG_KEY){
            let currentTime = Date().timeIntervalSince1970.milliseconds
            let timeSinceLastUpdate =  currentTime - savedConfig.dateSaved
            if timeSinceLastUpdate < updatePeriod &&  !isNewSession {
                print("No need to update")
                completion()
                return
            }
        }
        
        configFetcher.fetch {  config in
            if let newConfig = config{
                if isNewSession {
                    self.configRepo.save(newConfig, key: Constants.BTT_CURRENT_REMOTE_CONFIG_KEY)
                    self.configRepo.save(newConfig, key: Constants.BTT_BUFFER_REMOTE_CONFIG_KEY)
                }else{
                    self.configRepo.save(newConfig, key: Constants.BTT_BUFFER_REMOTE_CONFIG_KEY)
                }
            }
            completion()
        }
    }
}
