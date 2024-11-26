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
    
    private let updatePeriod: Millisecond = .hour
    private let configFetcher : ConfigurationFetcher
    private let configRepo : ConfigurationRepo
    private let logger : Logging?
    private var configAck: RemoteConfigAckReporter?
        
    init(configFetcher : ConfigurationFetcher, configRepo : ConfigurationRepo, logger: Logging?, configAck :RemoteConfigAckReporter?) {
        self.configFetcher = configFetcher
        self.configRepo = configRepo
        self.logger = logger
        self.configAck = configAck
    }
    
    func update(_ isNewSession : Bool, completion: @escaping () -> Void) {
        
        var enableRemoteConfigAck = true
        
        do {
            let config = try configRepo.get()
           
            if let savedConfig = config{
                
                enableRemoteConfigAck = savedConfig.enableRemoteConfigAck
                
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
                
                if newConfig.enableRemoteConfigAck{
                    enableRemoteConfigAck = true
                }
                
                do{
                    if self.configRepo.hasChange(newConfig) {
                        try  self.configRepo.save(newConfig)
                        self.reportSucessAck(enableRemoteConfigAck)
                    }
                    
                    self.logger?.info("Fetched remote config from end point \(newConfig.networkSampleRateSDK ?? 0)")
                }
                catch{
                    self.logger?.error("Fail to save remote config: \(error)")
                    self.reportFailAck(enableRemoteConfigAck, error)
                }
            }else{
                if let error = error{
                    self.logger?.error("Fail to fetch remote config: \(error)")
                    self.reportFailAck(enableRemoteConfigAck, error)
                }
            }
            
            completion()
        }
    }
    
    func reportFailAck(_ enableRemoteConfigAck : Bool, _ error : Error){
        if enableRemoteConfigAck {
            configAck?.reportFailAck(error)
        }
    }
    
    func reportSucessAck(_ enableRemoteConfigAck : Bool){
        if enableRemoteConfigAck {
            configAck?.reportSuccessAck()
        }
    }
}
