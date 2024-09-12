//
//  BTTConfigurationUpdater.swift
//  
//
//  Created by Ashok Singh on 05/09/24.
//

import Foundation

protocol ConfigurationUpdater {
    func update(completion: @escaping () -> Void)
}

class BTTConfigurationUpdater : ConfigurationUpdater {
    
    private let updatePeriod: Millisecond = .hour
    private let configFetcher : ConfigurationFetcher
    private let configRepo : ConfigurationRepo
    private let configHandler: RemoteConfigHandler
        
    init(configFetcher : ConfigurationFetcher, configRepo : ConfigurationRepo, configHandler : RemoteConfigHandler) {
        self.configFetcher = configFetcher
        self.configRepo = configRepo
        self.configHandler = configHandler
    }
    
    func update(completion: @escaping () -> Void) {
        if let savedConfig = configRepo.get() {
            let currentTime = Date().timeIntervalSince1970.milliseconds
            let timeSinceLastUpdate =  currentTime - savedConfig.dateSaved
            if timeSinceLastUpdate < updatePeriod {
                print("No need to update")
                completion()
                return
            }
        }
        
        configFetcher.fetch {  config in
            if let newConfig = config, self.hasUpdated(newConfig){
                print("Updating by updater saved config with new config \(Double(newConfig.wcdSamplePercent) / 100.0)")
                self.configRepo.save(newConfig)
                self.configHandler.updateRemoteConfig(newConfig)
            }else{
                print("Found same config as old saved config or unable to fetch")
            }
            completion()
        }
    }
    
    private func hasUpdated(_ newConfig : BTTRemoteConfig) -> Bool{
        print("Remote Config Value : \(newConfig)")
        if let savedConfig = self.configRepo.get(){
            if newConfig != savedConfig {
                return true
            }else{
                return false
            }
        }
        return true
    }
}
