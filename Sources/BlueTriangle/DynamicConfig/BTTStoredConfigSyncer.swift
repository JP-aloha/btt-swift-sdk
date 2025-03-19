//
//  ConfigSyncManager.swift
//  
//
//  Created by Ashok Singh on 21/01/25.
//


/// A utility class for synchronizing and managing the SDK's stored  remote configuration into the blue triangle configuration.
///
/// The `BTTStoredConfigSyncer` is responsible for ensuring that the SDK's locally stored
/// remote configuration remains up-to-date and consistent with the blue triangle configuration.
///
/// - Responsibilities:
///   - Synchronizes the locally cached remote configuration with the  blue triangle configuration.
///   - Handles storage and retrieval of configuration data to ensure seamless operation,
///     even when the remote API is unreachable.
///
/// - Key Features:
///   - Ensures the enable/disable state of the SDK is accurately reflected in the stored configuration.
///
class BTTStoredConfigSyncer {
    
    private let configRepo: BTTConfigurationRepo
    private let logger: Logging
    
    init(configRepo: BTTConfigurationRepo, logger: Logging) {
        self.configRepo = configRepo
        self.logger = logger
    }
    
    /// Evaluates the SDK's state based on the latest configuration and updates it accordingly.
    ///
    /// This method checks whether the SDK should be enabled or disabled based on the retrieved remote
    /// configuration, and updates the SDK state if necessary.
    ///
    /// - Notes:
    ///   - This method ensures that the SDK's behavior is in sync with the remote configuration
    ///
    func updateAndApplySDKState(){
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
