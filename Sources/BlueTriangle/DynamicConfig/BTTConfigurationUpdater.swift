//
//  BTTConfigurationUpdater.swift
//  
//
//  Created by Ashok Singh on 05/09/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

protocol ConfigurationUpdater {
    func update(_ isNewSession : Bool, completion: @escaping () -> Void)
}

class BTTConfigurationUpdater : ConfigurationUpdater {
    
    private let updatePeriod: Millisecond = 1//.hour
    private let configFetcher : ConfigurationFetcher
    private let configRepo : ConfigurationRepo
    private let logger : Logging?
        
    init(configFetcher : ConfigurationFetcher, configRepo : ConfigurationRepo, logger: Logging?) {
        self.configFetcher = configFetcher
        self.configRepo = configRepo
        self.logger = logger
    }
    
    func update(_ isNewSession : Bool, completion: @escaping () -> Void) {
        
        do {
            if let savedConfig = try configRepo.get(){
                let currentTime = Date().timeIntervalSince1970.milliseconds
                let timeIntervalSinceLastUpdate =  currentTime - savedConfig.dateSaved
                
                // Perform remote config update only if it's a new session or the update period has elapsed
                if timeIntervalSinceLastUpdate < updatePeriod &&  !isNewSession {
                    self.logger?.info("No need to update")
                    completion()
                    return
                }
            }
        }catch{
            self.logger?.error("Fail to get remote config : \(error)")
        }
        
        configFetcher.fetch {  config, error  in
            if let newConfig = config{
                do{
                    try  self.configRepo.save(newConfig)
                    self.logger?.info("Fetched remote config from end point")
                }
                catch{
                    self.logger?.error("Fail to save remote config: \(error)")
                }
            }else{
                if let error = error{
                    self.logger?.error("Fail to fetch remote config: \(error)")
                }
            }
            
            completion()
        }
    }
}
