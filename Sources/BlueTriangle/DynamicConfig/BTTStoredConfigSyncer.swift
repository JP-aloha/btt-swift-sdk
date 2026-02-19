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
    
    /// Synchronizes the configuration values from the stored repository.
    ///
    /// This method retrieves the latest remote configuration from the repository and applies it to the
    /// Blue triangle configuration. It updates key configuration values like the network sample rate and screens to
    /// ignore, .
    ///
    /// - Notes:
    ///   - This function ensures that the Blue triangle configuration is kept up-to-date.
    ///
    
    func syncConfigurationFromStorage() {
        do {
            guard let config = try configRepo.get() else { return }
            let defaultConfig = configRepo.defaultConfig
            syncNetworkSampleRate(from: config, defaultConfig: defaultConfig)
            syncIgnoreScreens(from: config, defaultConfig: defaultConfig)
            syncScreenTracking(from: config, defaultConfig: defaultConfig)
            syncGrouping(from: config, defaultConfig: defaultConfig)
            syncLaunchTime(from: config, defaultConfig: defaultConfig)
            syncNetworkStateTracking(from: config, defaultConfig: defaultConfig)
            syncCrashTracking(from: config, defaultConfig: defaultConfig)
            syncANRTracking(from: config, defaultConfig: defaultConfig)
            syncMemoryWarning(from: config, defaultConfig: defaultConfig)
            syncWebViewStitching(from: config, defaultConfig: defaultConfig)
            syncGroupingTapDetection(from: config, defaultConfig: defaultConfig)
            syncAutoCheckout(from: config, defaultConfig: defaultConfig)
        } catch {
            logger.error("BlueTriangle:SessionManager: Failed to retrieve remote configuration from the repository - \(error)")
        }
    }
    
    // MARK: - Individual sync helpers
    
    private func syncNetworkSampleRate(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig) {
        let sampleRate = config.networkSampleRateSDK ?? defaultConfig.networkSampleRateSDK
        
        if CommandLine.arguments.contains(Constants.FULL_SAMPLE_RATE_ARGUMENT) {
            BlueTriangle.updateNetworkSampleRate(1.0)
            return
        }
        
        if let rate = sampleRate {
            if rate == 0 {
                BlueTriangle.updateNetworkSampleRate(0.0)
            } else {
                BlueTriangle.updateNetworkSampleRate(Double(rate) / 100.0)
            }
        }
    }
    
    private func syncIgnoreScreens(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig) {
        let ignoreScreens = config.ignoreScreens ?? defaultConfig.ignoreScreens
        if let ignoreVcs = ignoreScreens {
            var unionOfIgnoreScreens = Set(ignoreVcs)
            if let defaultScreens = defaultConfig.ignoreScreens {
                unionOfIgnoreScreens = unionOfIgnoreScreens.union(Set(defaultScreens))
            }
            BlueTriangle.updateIgnoreVcs(unionOfIgnoreScreens)
        }
    }
    
    private func syncScreenTracking(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig) {
        if let enableScreenTracking = config.enableScreenTracking ?? defaultConfig.enableScreenTracking {
            BlueTriangle.updateScreenTracking(enableScreenTracking)
        }
    }
    
    private func syncGrouping(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig) {
        if let enableGrouping = config.enableGrouping ?? defaultConfig.enableGrouping,
           let groupingIdleTime = config.groupingIdleTime ?? defaultConfig.groupingIdleTime {
            BlueTriangle.updateGrouping(enableGrouping, idleTime: groupingIdleTime)
        }
    }
    
    private func syncLaunchTime(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig) {
        if let enableLaunchTime = config.enableLaunchTime ?? defaultConfig.enableLaunchTime {
            BlueTriangle.updateLaunchTime(enableLaunchTime)
        }
    }
    
    private func syncNetworkStateTracking(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig) {
        if let enableNetworkStateTracking = config.enableNetworkStateTracking ?? defaultConfig.enableNetworkStateTracking {
            BlueTriangle.updateTrackingNetworkState(enableNetworkStateTracking)
        }
    }
    
    private func syncCrashTracking(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig) {
        if let enableCrashTracking = config.enableCrashTracking ?? defaultConfig.enableCrashTracking {
            BlueTriangle.updateCrashTracking(enableCrashTracking)
        }
    }
    
    private func syncANRTracking(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig) {
        if let enableANRTracking = config.enableANRTracking ?? defaultConfig.enableANRTracking {
            BlueTriangle.updateAnrMonitoring(enableANRTracking)
        }
    }
    
    private func syncMemoryWarning(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig) {
        if let enableMemoryWarning = config.enableMemoryWarning ?? defaultConfig.enableMemoryWarning {
            BlueTriangle.updateMemoryWarning(enableMemoryWarning)
        }
    }
    
    private func syncWebViewStitching(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig) {
        if let enableWebViewStitching = config.enableWebViewStitching ?? defaultConfig.enableWebViewStitching {
            BlueTriangle.updateWebViewStitching(enableWebViewStitching)
        }
    }
    
    private func syncGroupingTapDetection(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig) {
        if let enableGroupingTapDetection = config.enableGroupingTapDetection ?? defaultConfig.enableGroupingTapDetection {
            BlueTriangle.updateGroupingTapDetection(enableGroupingTapDetection)
        }
    }
    
    private func syncAutoCheckout(from config: BTTRemoteConfig, defaultConfig: BTTRemoteConfig ) {
        
        if let enabled = config.checkoutTrackingEnabled
            ?? defaultConfig.checkoutTrackingEnabled {
            BlueTriangle.updateCheckoutTracking(enabled)
        }
        
        if let classNames = config.checkoutClassName
            ?? defaultConfig.checkoutClassName {
            BlueTriangle.updateCheckoutClassNames(classNames)
        }
        
        if let url = config.checkoutURL
            ?? defaultConfig.checkoutURL {
            BlueTriangle.updateCheckoutURL(url)
        }
        
        if let amount = config.checkoutAmount
            ?? defaultConfig.checkoutAmount {
            BlueTriangle.updateCheckoutAmount(amount)
        }
        
        if let cartCount = config.checkoutCartCount
            ?? defaultConfig.checkoutCartCount {
            BlueTriangle.updateCheckoutCartCount(cartCount)
        }
        
        if let cartCountCheckout = config.checkoutCartCountCheckout
            ?? defaultConfig.checkoutCartCountCheckout {
            BlueTriangle.updateCheckoutCartCountCheckout(cartCountCheckout)
        }
        
        if let orderNumber = config.checkoutOrderNumber
            ?? defaultConfig.checkoutOrderNumber {
            BlueTriangle.updateCheckoutOrderNumber(orderNumber)
        }
        
        if let timeValue = config.checkoutTimeValue
            ?? defaultConfig.checkoutTimeValue {
            BlueTriangle.updateCheckoutTimeValue(timeValue)
        }
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
