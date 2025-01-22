//
//  ConfigSyncManager.swift
//  
//
//  Created by Ashok Singh on 21/01/25.
//

class BTTStoredConfigSyncer {
    
    private let configRepo: BTTConfigurationRepo
    private let logger: Logging
    
    init(configRepo: BTTConfigurationRepo, logger: Logging) {
        self.configRepo = configRepo
        self.logger = logger
    }
    
    // Updates the configuration values in the session by retrieving the latest configuration from storage.
    func syncConfigurationFromStorage(){
        do{
            if let config = try configRepo.get(){
                
                //Sync Sample Rate
                let sampleRate = config.networkSampleRateSDK ?? configRepo.defaultConfig.networkSampleRateSDK
                
                if CommandLine.arguments.contains(Constants.FULL_SAMPLE_RATE_ARGUMENT) {
                    BlueTriangle.updateNetworkSampleRate(1.0)
                }
                else if let rate = sampleRate{
                    if rate == 0 {
                        BlueTriangle.updateNetworkSampleRate(0.0)
                    }else{
                        BlueTriangle.updateNetworkSampleRate(Double(rate) / 100.0)
                    }
                }
                
               // Sync Ignore Screens
                let ignoreScreens = config.ignoreScreens ?? configRepo.defaultConfig.ignoreScreens
                
                if let ignoreVcs = ignoreScreens{
                                       
                    var unianOfIgnoreScreens = Set(ignoreVcs)
                    
                    if let defaultScreens = configRepo.defaultConfig.ignoreScreens{
                        unianOfIgnoreScreens = unianOfIgnoreScreens.union(Set(defaultScreens))
                    }
                   
                    BlueTriangle.updateIgnoreVcs(unianOfIgnoreScreens)
                }
                
            }
        }catch{
            logger.error("BlueTriangle:SessionManager: Failed to retrieve remote configuration from the repository - \(error)")
        }
    }
    
    //Evaluate and update sdk state.
    func evaluateAndUpdateSDKState(){
        do{
            if let config = try configRepo.get(){
                let isEnable = config.enableAllTracking ?? true
                if BlueTriangle.initialized && isEnable != BlueTriangle.enableAllTracking{
                    BlueTriangle.enableAllTracking = isEnable
                    BlueTriangle.applyAllTrackerState()
                }
            }
        }
        catch {
            logger.error("BlueTriangle:SessionManager: Failed to retrieve remote configuration from the repository - \(error)")
        }
        
    }
}
