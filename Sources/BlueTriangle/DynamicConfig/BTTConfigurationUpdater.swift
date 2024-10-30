//
//  BTTConfigurationUpdater.swift
//  
//
//  Created by Ashok Singh on 05/09/24.
//

import Foundation
import Combine

protocol ConfigurationUpdater {
    func update(_ isNewSession : Bool, completion: @escaping (_ hasChanged : Bool) -> Void)
}

class BTTConfigurationUpdater : ConfigurationUpdater {
    
    private let updatePeriod: Millisecond = .hour
    private let configFetcher : ConfigurationFetcher
    private let configRepo : ConfigurationRepo
        
    init(configFetcher : ConfigurationFetcher, configRepo : ConfigurationRepo) {
        self.configFetcher = configFetcher
        self.configRepo = configRepo
    }
    
    func update(_ isNewSession : Bool, completion: @escaping (_ hasChanged : Bool) -> Void) {
       
        var hasConfigChanged = false
        
        if let savedConfig = configRepo.get(){
           
            let currentTime = Date().timeIntervalSince1970.milliseconds
            let timeIntervalSinceLastUpdate =  currentTime - savedConfig.dateSaved
            
            // Perform remote config update only if it's a new session or the update period has elapsed
            if timeIntervalSinceLastUpdate < updatePeriod &&  !isNewSession {
                print("No need to update")
                completion(hasConfigChanged)
                return
            }
        }
        
        configFetcher.fetch {  config in
            if let newConfig = config{
               
                if let oldConfig = self.configRepo.get(){
                    hasConfigChanged = newConfig == oldConfig ? false : true
                }else{
                    hasConfigChanged = true
                }
                
                self.configRepo.save(newConfig)
                
            }
            
            completion(hasConfigChanged)
        }
    }
}
