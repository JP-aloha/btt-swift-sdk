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
        
    init(configFetcher : ConfigurationFetcher, configRepo : ConfigurationRepo, logger: Logging, configAck :RemoteConfigAckReporter?) {
        self.configFetcher = configFetcher
        self.configRepo = configRepo
        self.logger = logger
        self.configAck = configAck
    }
    
    func update(_ isForcedUpdate : Bool, completion: @escaping () -> Void) {
        
        var enableRemoteConfigAck = false
        
        do {
            let config = try configRepo.get()
           
            if let savedConfig = config{
                
                enableRemoteConfigAck = savedConfig.enableRemoteConfigAck ?? false
                
                let currentTime = Date().timeIntervalSince1970.milliseconds
                let timeIntervalSinceLastUpdate =  currentTime - savedConfig.dateSaved
                
                // Perform remote config update only if it's a new session or the update period has elapsed
                if timeIntervalSinceLastUpdate < updatePeriod &&  !isForcedUpdate {
                   
                    self.logger?.info("BlueTriangle:BTTConfigurationUpdater - The update period has not yet elapsed.")
                    completion()
                    return
                }
            }
        }
        catch{
           
            self.logger?.error("BlueTriangle:BTTConfigurationUpdater: Failed to retrieve remote configuration from the repository - \(error.localizedDescription)")
        }
        
        configFetcher.fetch {  fetchedConfig, error  in
            
            if let config = fetchedConfig{
                
                enableRemoteConfigAck = config.enableRemoteConfigAck ?? false
                
                do{
                    if self.configRepo.hasChange(config) {
                        try  self.configRepo.save(config)
                        self.reportAck(enableRemoteConfigAck, config, nil)
                    }
                    
                    self.logger?.info("BlueTriangle:BTTConfigurationUpdater - Remote config fetched successfully sampleRate: \(config.networkSampleRateSDK ?? 0) groupingRate: \(config.groupedViewSampleRate ?? 0) - sdkAllTrackingEnable: \(config.enableAllTracking ?? true ? "true" : "false") - groupingEnable: \(config.enableGrouping ?? false ? "true" : "false") , screenTracking: \(config.enableScreenTracking ?? false ? "true" : "false") , launchTime: \(config.enableLaunchTime ?? false ? "true" : "false"), anrTracking: \(config.enableANRTracking ?? false ? "true" : "false"), crashTracking: \(config.enableCrashTracking ?? false ? "true" : "false"), memoryWarning: \(config.enableMemoryWarning ?? false ? "true" : "false"), networkState: \(config.enableNetworkStateTracking ?? false ? "true" : "false"), webStiching: \(config.enableWebViewStitching ?? false ? "true" : "false") , groupTapDetection: \(config.enableGroupingTapDetection ?? false ? "true" : "false")")
                }
                catch{
                    self.logger?.error("BlueTriangle:BTTConfigurationUpdater - Failed to save fetch remote config: \(error.localizedDescription)")
                }
            }
            else if let networkError = error {
               
                let errorMessage = networkError.getErrorMessage()
                self.reportAck(enableRemoteConfigAck, nil, errorMessage)
                self.logger?.error("BlueTriangle:BTTConfigurationUpdater - Failed to fetch remote config: \(errorMessage)")
            }
            else{
                if let error = error{
                    
                    self.logger?.error("BlueTriangle:BTTConfigurationUpdater - Failed to fetch remote config: \(error.localizedDescription)")
                    self.reportAck(enableRemoteConfigAck, nil, error.localizedDescription)
                }
            }
            
            completion()
        }
    }
}

extension BTTConfigurationUpdater{
   
    private func reportAck(_ enableRemoteConfigAck : Bool, _ fetchedConfig : BTTRemoteConfig?,  _ error : String?){
        if enableRemoteConfigAck{
            if let _ = fetchedConfig{
                reportSucessAck()
            }
            else{
                if let errorMessage = error{
                    reportFailAck(errorMessage)
                }
            }
        }
    }

    private func reportFailAck(_ error : String){
        configAck?.reportFailAck(error)
    }
    
    private func reportSucessAck(){
        configAck?.reportSuccessAck()
    }
}
