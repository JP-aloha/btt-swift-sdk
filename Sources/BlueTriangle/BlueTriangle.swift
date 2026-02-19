//
//  BlueTriangle.swift
//
//  Created by Mathew Gacy on 10/8/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
#if canImport(AppEventLogger)
import AppEventLogger
#endif

#if canImport(UIKit)
import UIKit
#endif

typealias SessionProvider = () -> Session?

/// The entry point for interacting with the Blue Triangle SDK.
@preconcurrency
final public class BlueTriangle: NSObject {
    
    internal static var groupTimer : BTTimerGroupManager = BTTimerGroupManager(logger: logger)
    internal static var configuration = BlueTriangleConfiguration()
    internal static let globleProperty = GlobalProperties()
    internal static let checkoutEvent = CheckoutEventReporter(logger: logger)
    
    private static var _screenTracker: BTTScreenLifecycleTracker?
    internal static var screenTracker: BTTScreenLifecycleTracker?{
        get {
            trackingLock.sync { _screenTracker }
        }
        set{
            trackingLock.sync { _screenTracker = newValue }
        }
    }
    private static var _networkStateMonitor: NetworkStateMonitorProtocol?
    internal static var networkStateMonitor: NetworkStateMonitorProtocol?{
        get {
            trackingLock.sync { _networkStateMonitor }
        }
        set{
            trackingLock.sync { _networkStateMonitor = newValue }
        }
    }
    
    private static var _appEventObserver: AppEventObserver?
    internal static var appEventObserver: AppEventObserver?{
        get {
            trackingLock.sync { _appEventObserver }
        }
        set{
            trackingLock.sync { _appEventObserver = newValue }
        }
    }
    
    private static var _nsExeptionReporter: CrashReportManaging?
    private static var nsExeptionReporter: CrashReportManaging?{
        get {
            trackingLock.sync { _nsExeptionReporter }
        }
        set{
            trackingLock.sync { _nsExeptionReporter = newValue }
        }
    }
    
    private static var _signalCrashReporter: BTSignalCrashReporter?
    internal static var signalCrashReporter: BTSignalCrashReporter?{
        get {
            trackingLock.sync { _signalCrashReporter }
        }
        set{
            trackingLock.sync { _signalCrashReporter = newValue }
        }
    }
    
    private static var _launchTimeReporter : LaunchTimeReporter?
    internal static var launchTimeReporter : LaunchTimeReporter?{
        get {
            trackingLock.sync { _launchTimeReporter }
        }
        set{
            trackingLock.sync { _launchTimeReporter = newValue }
        }
    }
    
    private static var _memoryWarningWatchDog : MemoryWarningWatchDog?
    internal static var memoryWarningWatchDog : MemoryWarningWatchDog?{
        get {
            trackingLock.sync { _memoryWarningWatchDog }
        }
        set{
            trackingLock.sync { _memoryWarningWatchDog = newValue }
        }
    }
    
    private static var _anrWatchDog : ANRWatchDog?
    internal static var anrWatchDog : ANRWatchDog?{
        get {
            trackingLock.sync { _anrWatchDog }
        }
        set{
            trackingLock.sync { _anrWatchDog = newValue }
        }
    }
    
    private static var _sessionManager : SessionManagerProtocol?
    private static var sessionManager : SessionManagerProtocol?{
        get {
            trackingLock.sync { _sessionManager }
        }
        set{
            trackingLock.sync { _sessionManager = newValue }
        }
    }
    
    internal static var clarityConnector = ClaritySessionConnector(logger: logger)
   
    private static var _enableAllTracking: Bool = configRepo.isEnableAllTracking()
    internal static var enableAllTracking: Bool {
         get { enableAllTrackingLock.sync { return _enableAllTracking } }
         set { enableAllTrackingLock.sync { _enableAllTracking = newValue } }
     }
    
    private static let configRepo: BTTConfigurationRepo = {
        let config = BTTConfigurationRepo(BTTRemoteConfig.defaultConfig)
        return  config
    }()

    internal static let disableModeSessionManager : SessionManagerProtocol = {
        let configFetcher  =  BTTConfigurationFetcher(logger: logger)
        let configSyncer = BTTStoredConfigSyncer(configRepo: configRepo, logger: logger)
        let updater  =  BTTConfigurationUpdater(configFetcher: configFetcher, configRepo: configRepo, logger: logger, configAck: nil)
        return DisableModeSessionManager(logger, configRepo, updater, configSyncer)
    }()
    
    internal static let enabledModeSessionManager : SessionManagerProtocol = {
        let configFetcher  =  BTTConfigurationFetcher(logger: logger)
        let configSyncer = BTTStoredConfigSyncer(configRepo: configRepo, logger: logger)
        let configAck  =  RemoteConfigAckReporter(logger: logger, uploader: uploader)
        let updater  =  BTTConfigurationUpdater(configFetcher: configFetcher, configRepo: configRepo, logger: logger, configAck: configAck)
        return SessionManager(logger, configRepo, updater, configSyncer)
    }()
    
    private static let lock = NSLock()
    private static let timerLock = NSLock()
    private static let groupCaptureLock = NSLock()
    private static let networkCaptureLock = NSLock()
    private static let trackingLock = NSRecursiveLock()
    private static let enableAllTrackingLock = NSLock()
    private static let appInitializeLock = NSLock()
    private static var activeTimers = [BTTimer]()
#if os(iOS)
    private static let matricKitWatchDog = MetricKitWatchDog()
#endif
    internal static func addActiveTimer(_ timer : BTTimer){
        timerLock.sync {
            activeTimers.append(timer)
#if os(iOS)
         //   matricKitWatchDog.saveCurrentTimerData(timer)
#endif
        }
    }
    
    internal static func removeActiveTimer(_ timer : BTTimer){
        timerLock.sync {
            self.activeTimers.removeAll { $0.uuid == timer.uuid }
        }
    }
    
    internal static func recentTimer() -> BTTimer?{
        timerLock.sync {
            let timer = activeTimers.last
            return timer
        }
    }
    
    internal static func updateSession(_ session : SessionData){
    
        _session?.sessionID = session.sessionID
#if os(iOS)
        BTTWebViewTracker.updateSessionId(session.sessionID)
#endif
        SignalHandler.updateSessionID("\(session.sessionID)")
    }
    
    private static var _session: Session? = {
        configuration.makeSession()
    }()
    
    internal static func session() -> Session? {
        return _session
    }
    
    internal static func sessionData() -> SessionData? {
        return sessionManager?.getSessionData()
    }
    
    private static func makeCapturedRequestCollector() -> CapturedRequestCollecting? {
        if let _ = session(), shouldCaptureRequests {
            let collector = configuration.capturedRequestCollectorConfiguration.makeRequestCollector(
                logger: logger,
                networkCaptureConfiguration: .standard,
                requestBuilder: CapturedRequestBuilder.makeBuilder {self.session()},
                uploader: uploader)

            Task {
                await collector.configure()
            }
            return collector
        } else {
            return nil
        }
    }
    
    internal static func makeCapturedGroupRequestCollector() -> CapturedGroupRequestCollecting? {
        if let _ = session(), shouldCaptureRequests, configuration.enableGrouping {
            let groupCollector = configuration.capturedGroupRequestCollectorConfiguration.makeRequestCollector(
                logger: logger,
                networkCaptureConfiguration: .standard,
                requestBuilder: CapturedRequestBuilder.makeBuilder {self.session()},
                uploader: uploader)
            return groupCollector
        } else {
            return nil
        }
    }
    
    internal static func makeCapturedActionRequestCollector() -> CapturedActionRequestCollecting? {
        if let _ = session(), shouldCaptureRequests {
            let actionsCollector = configuration.capturedActionsRequestCollectorConfiguration.makeRequestCollector(
                logger: logger,
                networkCaptureConfiguration: .standard,
                requestBuilder: CapturedRequestBuilder.makeBuilder {self.session()},
                uploader: uploader)
            return actionsCollector
        } else {
            return nil
        }
    }
    
    private static var logger: Logging = {
        configuration.makeLogger()
    }()

    private static var uploader: Uploading = {
        configuration.uploaderConfiguration.makeUploader(
            logger: logger,
            failureHandler: RequestFailureHandler(
                file: .requests,
                logger: logger))
    }()

    private static var timerFactory: (Page, BTTimer.TimerType, Bool) -> BTTimer = {
        configuration.timerConfiguration.makeTimerFactory(
            logger: logger,
            performanceMonitorFactory: configuration.makePerformanceMonitorFactory())
    }()

    private static var internalTimerFactory: () -> InternalTimer = {
        configuration.internalTimerConfiguration.makeTimerFactory(logger: logger)
    }()

    internal static var shouldCaptureRequests: Bool = {
        sessionData()?.shouldNetworkCapture ?? false
    }()
    
    internal static var shouldCheckoutTracking: Bool = {
        sessionData()?.checkoutTrackingEnabled ?? false
    }()
    
    /// A Boolean value indicating  whether the SDK has been successfully configured and initialized.
    ///
    /// - `true`: The SDK has been configured and is ready to function. This means
    ///           that all necessary setup steps have been completed.
    /// - `false`: The SDK has not been configured. In this state, the SDK will not
    ///            function correctly, including the ability to fetch updates for the
    ///            enable/disable state via the Remote Configuration Updater.
    ///
    private static var _initialized = false
    
    public static var initialized: Bool {
        get { appInitializeLock.sync { _initialized } }
        set { appInitializeLock.sync { _initialized = newValue } }
    }
    
    private static var _capturedRequestCollector: CapturedRequestCollecting? = {
        return makeCapturedRequestCollector()
    }()
    
    private static var _capturedGroupedViewRequestCollector: CapturedGroupRequestCollecting? = {
        return makeCapturedGroupRequestCollector()
    }()
    
    private static var capturedActionsViewRequestCollector: CapturedActionRequestCollector? = {
        return makeCapturedActionRequestCollector() as! CapturedActionRequestCollector
    }()
    
    private static func getNetworkRequestCapture() -> CapturedRequestCollecting? {
        networkCaptureLock.sync {
            return _capturedRequestCollector
        }
    }
    
    private static func setNetworkRequestCapture(_ requestCapture :CapturedRequestCollecting?) {
        networkCaptureLock.sync {
            _capturedRequestCollector = requestCapture
        }
    }
    
    private static func setGroupRequestCapture(_ groupCapture :CapturedGroupRequestCollecting?) {
        groupCaptureLock.sync {
            _capturedGroupedViewRequestCollector = groupCapture
        }
    }
    
    internal static func getGroupRequestCapture() -> CapturedGroupRequestCollecting? {
        groupCaptureLock.sync {
            return _capturedGroupedViewRequestCollector
        }
    }
    
    //Cache components
    internal static var payloadCache : PayloadCacheProtocol = {
        PayloadCache.init(configuration.cacheMemoryLimit,
                          expiry: configuration.cacheExpiryDuration)
    }()
    
    
    /// Blue Triangle Technologies-assigned site ID.
    @objc public static var siteID: String {
        trackingLock.sync { session()?.siteID ?? configuration.siteID }
    }

    /// Global User ID.
    @objc public static var globalUserID: Identifier {
        lock.sync { session()?.globalUserID ?? configuration.globalUserID }
    }

    /// Session ID.
    @objc public static var sessionID: Identifier {
        get {
            lock.sync { session()?.sessionID ??  Identifier()}
        }
    }

    /// Boolean value indicating whether user is a returning visitor.
    @objc public static var isReturningVisitor: Bool {
        get {
            lock.sync { session()?.isReturningVisitor ?? configuration.isReturningVisitor }
        }
        set {
            lock.sync {_session?.isReturningVisitor = newValue }
        }
    }
    
    /// Traffic segment.
    @objc public static var trafficSegmentName: String {
         get {
            lock.sync { session()?.trafficSegmentName ?? "" }
        }
        set {
            lock.sync { _session?.trafficSegmentName = newValue }
        }
    }
    
    /// page type
    @objc public static var pageType: String {
         get {
            lock.sync { session()?.pageType ?? "" }
        }
        set {
            lock.sync { _session?.pageType = newValue }
        }
    }

    /// A/B testing identifier.
    @available(*, deprecated, message: "Use `func setAbTestID:` instead.")
    public static var abTestID: String {
        get {
            lock.sync { globleProperty.getGlobalProperties().abTestID ?? configuration.abTestID}
        }
        set {
            lock.sync { globleProperty.updateAbTestID(newValue) }
        }
    }

    /// Legacy campaign name.
    @available(*, deprecated, message: "Use `campaignName` instead.")
    @objc public static var campaign: String? {
        get {
            lock.sync { session()?.campaign ?? "" }
        }
        set {
            lock.sync { _session?.campaign = newValue}
        }
    }

    /// Campaign medium.
    @available(*, deprecated, message: "Use `func setCampaignMedium:` instead.")
     public static var campaignMedium: String {
        get {
            lock.sync { globleProperty.getGlobalProperties().campaignMedium ?? ""}
        }
        set {
            lock.sync { globleProperty.updateCampaignMedium(newValue) }
        }
    }

    /// Campaign name.
    @available(*, deprecated, message: "Use `func setCampaignName:` instead.")
    public static var campaignName: String {
        get {
            lock.sync { globleProperty.getGlobalProperties().campaignName ?? "" }
        }
        set {
            lock.sync { globleProperty.updateCampaignName(newValue)}
        }
    }

    /// Campaign source.
    @available(*, deprecated, message: "Use `func setCampaignSource:` instead.")
    public static var campaignSource: String {
        get {
            lock.sync { globleProperty.getGlobalProperties().campaignSource ?? "" }
        }
        set {
            lock.sync { globleProperty.updateCampaignSource(newValue)}
        }
    }

    /// Data center.
    @available(*, deprecated, message: "Use `func setDataCenter:` instead.")
    public static var dataCenter: String {
        get {
            lock.sync { globleProperty.getGlobalProperties().dataCenter ?? "" }
        }
        set {
            lock.sync { globleProperty.updateDataCenter(newValue) }
        }
    }
    
    /// Sets the value for AbTestID.
    ///
    /// This value is applied to all timers submitted after this call.
    /// The setting remains active until it is explicitly changed.
    ///
    /// Use `nil` to clear the current value.
    ///
    /// - Parameter value: The AbTestID value, or `nil` to reset.
    ///
    @objc(setAbTestID:)
    public static func setAbTestID(_ id: String?) {
        lock.sync { globleProperty.updateAbTestID(id) }
    }
    
    /// Sets the value for CampaignMedium.
    ///
    /// This value is applied to all timers submitted after this call.
    /// The setting remains active until it is explicitly changed.
    ///
    /// Use `nil` to clear the current value.
    ///
    /// - Parameter value: The CampaignMedium value, or `nil` to reset.
    ///
    @objc(setCampaignMedium:)
    public static func setCampaignMedium(_ value: String?) {
        lock.sync { globleProperty.updateCampaignMedium(value) }
    }
    
    /// Sets the value for CampaignName.
    ///
    /// This value is applied to all timers submitted after this call.
    /// The setting remains active until it is explicitly changed.
    ///
    /// Use `nil` to clear the current value.
    ///
    /// - Parameter value: The CampaignName value, or `nil` to reset.
    ///
    @objc(setCampaignName:)
    public static func setCampaignName(_ value: String?) {
        lock.sync { globleProperty.updateCampaignName(value)}
    }
    
    /// Sets the value for CampaignSource.
    ///
    /// This value is applied to all timers submitted after this call.
    /// The setting remains active until it is explicitly changed.
    ///
    /// Use `nil` to clear the current value.
    ///
    /// - Parameter value: The CampaignSource value, or `nil` to reset.
    ///
    @objc(setCampaignSource:)
    public static func setCampaignSource(_ value: String?) {
        lock.sync { globleProperty.updateCampaignSource(value)}
    }

    /// Sets the value for DataCenter.
    ///
    /// This value is applied to all timers submitted after this call.
    /// The setting remains active until it is explicitly changed.
    ///
    /// Use `nil` to clear the current value.
    ///
    /// - Parameter value: The DataCenter value, or `nil` to reset.
    ///
    @objc(setDataCenter:)
    public static func setDataCenter(_ value: String?) {
        lock.sync { globleProperty.updateDataCenter(value)}
    }
    
    /// Sets the value for Custom Category 1.
    ///
    /// This value is applied to all timers submitted after this call.
    /// The setting remains active until it is explicitly changed.
    ///
    /// Use `nil` to clear the current value.
    ///
    /// - Parameter value: The custom category value, or `nil` to reset.
    ///
    @objc(setCustomCategory1:)
    public static func setCustomCategory1(_ value: String?) {
        lock.sync { globleProperty.updateCustomCategory1(value)}
    }
    
    /// Sets the value for Custom Category 2.
    ///
    /// This value is applied to all timers submitted after this call.
    /// The setting remains active until it is explicitly changed.
    ///
    /// Use `nil` to clear the current value.
    ///
    /// - Parameter value: The custom category value, or `nil` to reset.
    ///
    @objc(setCustomCategory2:)
    public static func setCustomCategory2(_ value: String?) {
        lock.sync { globleProperty.updateCustomCategory2(value)}
    }
    
    /// Sets the value for Custom Category 3.
    ///
    /// This value is applied to all timers submitted after this call.
    /// The setting remains active until it is explicitly changed.
    ///
    /// Use `nil` to clear the current value.
    ///
    /// - Parameter value: The custom category value, or `nil` to reset.
    ///
    @objc(setCustomCategory3:)
    public static func setCustomCategory3(_ value: String?) {
        lock.sync { globleProperty.updateCustomCategory3(value)}
    }
    
    /// Sets the value for Custom Category 4.
    ///
    /// This value is applied to all timers submitted after this call.
    /// The setting remains active until it is explicitly changed.
    ///
    /// Use `nil` to clear the current value.
    ///
    /// - Parameter value: The custom category value, or `nil` to reset.
    ///
    @objc(setCustomCategory4:)
    public static func setCustomCategory4(_ value: String?) {
        lock.sync { globleProperty.updateCustomCategory4(value)}
    }
    
    /// Sets the value for Custom Category 5.
    ///
    /// This value is applied to all timers submitted after this call.
    /// The setting remains active until it is explicitly changed.
    ///
    /// Use `nil` to clear the current value.
    ///
    /// - Parameter value: The custom category value, or `nil` to reset.
    ///
    @objc(setCustomCategory5:)
    public static func setCustomCategory5(_ value: String?) {
        lock.sync { globleProperty.updateCustomCategory5(value)}
    }

    /// Custom metrics.
     private static var metrics: [String: AnyCodable] {
        get {
            lock.sync { session()?.metrics ?? [:] }
        }
        set {
            lock.sync {
                
                self._session?.metrics = (newValue.isEmpty ? nil : newValue)
                
            }
        }
    }
}

extension BlueTriangle {
    
    // Starts a session if it's not already started
    private static func startSession(){
        if _session == nil{
            _session = configuration.makeSession()
        }
        
        logger.info("BlueTriangle :: Session has started.")
    }
    
    // Ends the current session and logs the action
    private static func endSession(){
        _session = nil
        logger.info("BlueTriangle :: Session was ended due to SDK disable.")
    }
    
    // Starts HTTP network capture and updates capture requests
    private static func startHttpNetworkCapture(){
        self.updateCaptureRequests()
        logger.info("BlueTriangle :: HTTP network capture has started.")
    }
    
    // Stops HTTP network capture and clears captured requests
    private static func stopHttpNetworkCapture(){
        self.setNetworkRequestCapture(nil)
        logger.info("BlueTriangle :: HTTP network capture was stopped due to SDK disable.")
    }
    
    // Starts HTTP network capture and updates capture requests
    private static func startHttpGroupedChildCapture(){
        self.updateCaptureRequests()
        logger.info("BlueTriangle :: Grouped child view capture has started.")
    }
    
    // Stops HTTP network capture and clears captured requests
    private static func stopHttpGroupedChildCapture(){
        self.setGroupRequestCapture(nil)
        logger.info("BlueTriangle :: Grouped child view capture was stopped due to SDK disable.")
    }
    
    // Starts launch time collection and reporting if not already configured
    private static func startLaunchTime(){
        if launchTimeReporter == nil{
            configureLaunchTime(with: configuration.enableLaunchTime)
        }
        
        logger.info("BlueTriangle :: Launch time collection and reporting has started.")
    }
    
    // Stops launch time collection and reporting
    private static func stopLaunchTime(){
        launchTimeReporter?.stop()
        launchTimeReporter = nil
        
        logger.info("BlueTriangle :: Launch time collection and reporting were stopped due to SDK disable.")
    }
    
    // Starts crash tracking for both exceptions and signals
    private static func startNsAndSignalCrashTracking(){
        if let crashConfig = configuration.crashTracking.configuration {
            DispatchQueue.global(qos: .utility).async {
                if nsExeptionReporter == nil{
                    configureCrashTracking(with: crashConfig)
                }
                
                if signalCrashReporter == nil{
                    configureSignalCrash(with: crashConfig, debugLog: configuration.enableDebugLogging)
                }
            }
        }
        
        logger.info("BlueTriangle :: Crash tracking has started.")
    }
    
    // Stops crash tracking for both exceptions and signals
    private static func stopNsAndSignalCrashTracking(){
        nsExeptionReporter?.stop()
        nsExeptionReporter = nil
        signalCrashReporter?.stop()
        signalCrashReporter = nil
        
        logger.info("BlueTriangle :: Crash tracking was stopped due to SDK disable.")
    }
    
    // Starts memory warning tracking if not already configured
    private static func startMemoryWarning(){
        if memoryWarningWatchDog == nil{
            configureMemoryWarning(with: configuration.enableMemoryWarning)
        }
        
        logger.info("BlueTriangle :: Memory warning tracking has started.")
    }
    
    // Stops memory warning tracking
    private static func stopMemoryWarning(){
        memoryWarningWatchDog?.stop()
        memoryWarningWatchDog = nil
        
        logger.info("BlueTriangle :: Memory warning tracking was stopped due to SDK disable.")
    }
    
    // Starts ANR tracking if not already configured
    private static func startANR(){
        if anrWatchDog == nil{
            configureANRTracking(with: configuration.ANRMonitoring, enableStackTrace: configuration.ANRStackTrace,
                                 interval: configuration.ANRWarningTimeInterval)
        }
        
        logger.info("BlueTriangle :: ANR tracking has started.")
    }
    
    // Stops ANR tracking
    private static func stopANR(){
        anrWatchDog?.stop()
        anrWatchDog = nil
        
        logger.info("BlueTriangle :: ANR tracking was stopped due to SDK disable.")
    }
    
    // Starts screen tracking if not already configured
    private static func startScreenTracking(){
        if screenTracker == nil{
            
            configureScreenTracking(with: configuration.enableScreenTracking)
        }
        
        logger.info("BlueTriangle :: Screen tracking has started.")
    }
    
    // Stops screen tracking
    private static func stopScreenTracking(){
        screenTracker?.stop()
        screenTracker = nil
        
        logger.info("BlueTriangle :: Screen tracking was stopped due to SDK disable.")
    }
    
    // Starts network state tracking if not already configured
    private static func startNetworkStatus(){
        if networkStateMonitor == nil{
            configureMonitoringNetworkState(with: configuration.enableTrackingNetworkState)
        }
        
        logger.info("BlueTriangle :: Network state tracking has started.")
    }
    
    // Stops network state tracking
    private static func stopNetworkStatus(){
        networkStateMonitor?.stop()
        networkStateMonitor = nil
        
        logger.info("BlueTriangle :: Network state tracking was stopped due to SDK disable.")
    }
    
    private static func clearAllCache(){
        do{
            let payloadCache = BlueTriangle.payloadCache
            self._session?.metrics = [:]
            try payloadCache.deleteAll()
        }catch{
            logger.info("BlueTriangle :: Fail to clear cache \(error).")
        }
    }
}

// MARK: - Configuration
extension BlueTriangle {

    /// `configure` is a one-time configuration function to set session-level properties.
    /// - Parameter configure: A closure that enables mutation of the Blue Triangle SDK configuration.
    @objc
    public static func configure(_ configure: (BlueTriangleConfiguration) -> Void) {
        lock.sync {
            configure(configuration)
        }
        
        self.applyAllTrackerState()
        
        lock.sync {
            initialized.toggle()
        }
    }
    
    /// Applies the appropriate tracker state based on the current configuration.
    ///
    /// This method ensures that all SDK trackers are either started or stopped,
    /// depending on the `enableAllTracking` flag.
    ///
    /// - Behavior:
    ///   - If `enableAllTracking` is true, all trackers are started to enable SDK functionality.
    ///   - If `enableAllTracking` is false, all trackers are stopped to disable SDK functionality,
    ///     except for the Remote Configuration Updater, which remains active.
    ///
    ///
    internal static func applyAllTrackerState() {
        lock.sync {
            
            self.configureSessionManager(forModeWithExpiry: configuration.sessionExpiryDuration)
            
            if self.enableAllTracking {
                self.startAllTrackers()
            }
            else{
                self.stopAllTrackers()
            }
        }
    }
    
    /// Starts all trackers to enable the full functionality of the SDK.
    ///
    /// This method is responsible for initializing and activating all tracking mechanisms
    /// provided by the SDK. These include screen tracking, ANR detection, crash reporting,
    /// memory warning observation, network activity monitoring, launch time tracking, and more.
    ///
    /// - Note: This method is called when `enableAllTracking` is true, indicating that
    ///         the SDK should be fully operational.
    ///
    private static func startAllTrackers() {
        
        logger.info("BlueTriangle :: SDK is in enabled mode.")
        
        self.startSession()
        self.startHttpNetworkCapture()
        self.startHttpGroupedChildCapture()
        self.startScreenTracking()
        
        if  BlueTriangle.configuration.crashTracking == .nsException {
            self.startNsAndSignalCrashTracking()
        }
        
        if  BlueTriangle.configuration.enableMemoryWarning {
            self.startMemoryWarning()
        }
        
        if BlueTriangle.configuration.ANRMonitoring {
            self.startANR()
        }
        
        if BlueTriangle.configuration.enableTrackingNetworkState {
            self.startNetworkStatus()
        }
        
        if BlueTriangle.configuration.enableLaunchTime {
            self.startLaunchTime()
        }
    }
    
    /// Stops all trackers to disable the functionality of the SDK.
    ///
    /// This method is responsible for deactivating all tracking mechanisms provided by the SDK,
    /// including screen tracking, ANR detection, crash reporting, memory warning observation,
    /// network activity monitoring, launch time tracking, and other related features.
    ///
    /// - Note: This method is called when `enableAllTracking` is false, ensuring that the SDK
    ///         ceases all tracking activity. However, the **Remote Configuration Updater**
    ///         remains active to monitor and update the enable/disable state.
    ///
    private static func stopAllTrackers() {
        
        logger.info("BlueTriangle :: SDK is in disabled mode.")
        
        self.endSession()
        self.stopHttpNetworkCapture()
        self.stopHttpGroupedChildCapture()
        self.stopNsAndSignalCrashTracking()
        self.stopMemoryWarning()
        self.stopANR()
        self.stopScreenTracking()
        self.stopNetworkStatus()
        self.stopLaunchTime()
        self.clearAllCache()
    }

    // We want to allow multiple configurations for testing
    internal static func reconfigure(
        configuration: BlueTriangleConfiguration = .init(),
        session: Session? = nil,
        logger: Logging? = nil,
        uploader: Uploading? = nil,
        timerFactory: ((Page, BTTimer.TimerType, Bool) -> BTTimer)? = nil,
        shouldCaptureRequests: Bool? = nil,
        internalTimerFactory: (() -> InternalTimer)? = nil,
        requestCollector: CapturedRequestCollecting? = nil
    ) {
        
        lock.sync {
            
            self.configuration = configuration
            initialized = true
            if let session = session {
                self._session = session
            }
            if let logger = logger {
                self.logger = logger
            }
            if let uploader = uploader {
                self.uploader = uploader
            }
            if let timerFactory = timerFactory {
                self.timerFactory = timerFactory
            }
            if let shouldCaptureRequests = shouldCaptureRequests {
                self.shouldCaptureRequests = shouldCaptureRequests
            }
            if let internalTimerFactory = internalTimerFactory {
                self.internalTimerFactory = internalTimerFactory
            }
            self.setNetworkRequestCapture(requestCollector)
        }
    }
}

// MARK: - Timer
public extension BlueTriangle {
    /// Creates a timer timer to measure the duration of a user interaction.
    ///
    /// The returned timer is not running. Call ``BTTimer/start()`` before passing to ``endTimer(_:purchaseConfirmation:)``.
    ///
    /// - note: ``configure(_:)`` must be called before attempting to create a timer.
    ///
    /// - Parameters:
    ///   - page: An object providing information about the user interaction being timed.
    ///   - timerType: The type of timer.
    /// - Returns: The new timer.
    @objc
    static func makeTimer(page: Page, timerType: BTTimer.TimerType = .main, isGroupedTimer: Bool = false) -> BTTimer {
        lock.lock()
       // precondition(initialized, "BlueTriangle must be initialized before sending timers.")
        let timer = timerFactory(page, timerType, isGroupedTimer)
        lock.unlock()
        return timer
    }

    /// Creates a running timer to measure the duration of a user interaction.
    ///
    /// - note: ``configure(_:)`` must be called before attempting to start a timer.
    ///
    /// - Parameters:
    ///   - page: An object providing information about the user interaction being timed.
    ///   - timerType: The type of timer.
    /// - Returns: The running timer.
    @objc
    static func startTimer(page: Page, timerType: BTTimer.TimerType = .main, isGroupedTimer: Bool = false) -> BTTimer {
        let timer = makeTimer(page: page, timerType: timerType, isGroupedTimer: isGroupedTimer)
        timer.start()
        return timer
    }

    /// Ends a timer and upload it to Blue Triangle for processing.
    /// - Parameters:
    ///   - timer: The timer to upload.
    ///   - purchaseConfirmation: An object describing a purchase confirmation interaction.
    @objc
    static func endTimer(_ timer: BTTimer, purchaseConfirmation: PurchaseConfirmation? = nil) {
        timer.end()
        
        self.clarityConnector.refreshClaritySessionUrlCustomVariable()
        
        if let session = session(), timer.enableAllTracking {
            purchaseConfirmation?.orderTime = timer.endTime
            let request: Request
            lock.lock()
            do {
                request = try configuration.requestBuilder.builder(session, timer, purchaseConfirmation)
                lock.unlock()
            } catch {
                lock.unlock()
                logger.error(error.localizedDescription)
                return
            }
            uploader.send(request: request)
            
            anrWatchDog?.uploadAnrReportForPage(pageName: timer.getPageName(), uuid: timer.uuid, segment: timer.getTrafficSegment(), pageType: timer.page.pageType)
            memoryWarningWatchDog?.uploadMemoryWarningReport(pageName: timer.getPageName(), uuid: timer.uuid, segment: timer.getTrafficSegment(), pageType: timer.page.pageType)
            nsExeptionReporter?.uploadErrorForPage(pageName: timer.getPageName(), uuid: timer.uuid, segment: timer.getTrafficSegment(), pageType: timer.page.pageType)
        }
    }
}

// MARK: - Custom Metrics
public extension BlueTriangle{
    
    private static func _setCustomVariable(_ value: Any?, _ key: String) {
        
        guard enableAllTracking else{
            return
        }
        
        if let value = value {
            do {
                let anyValue = try AnyCodable(value)
                self.metrics[key] = anyValue
            } catch {
                logger.error("Unable to convert \(value) to an `Encodable` representation.")
            }
        }else{
            self.metrics.removeValue(forKey: key)
        }
    }
    
    private static func _getCustomVariable(_ key: String) -> String? {
        
        guard enableAllTracking else{
            return nil
        }
        
        if let stringValue = self.metrics[key]?.stringValue {
            return stringValue
        } else if let doubleValue = self.metrics[key]?.doubleValue {
            return String(doubleValue)
        } else if let boolValue = self.metrics[key]?.boolValue{
            return String(boolValue)
        } else if let intValue = self.metrics[key]?.intValue {
            return String(intValue)
        } else if let int64Value = self.metrics[key]?.int64Value {
            return String(int64Value)
        } else if let uint64Value = self.metrics[key]?.uint64Value{
            return String(uint64Value)
        }
        return nil
    }
    
    /// Sets a custom variable with the specified name and string value.
    ///
    /// - Parameters:
    ///   - name: The name of the custom variable to set.
    ///   - value: The string value to associate with the variable.
    ///            If the `name` already exists, `value` replaces the existing associated value. If `name`
    ///            isn’t already a key in the dictionary, the `(name, value)` pair is added.
    ///
    /// This method allows setting a custom variable where the associated value is of type `String`.
    ///
    @objc(setCustomVariable:strValue:)
    static func setCustomVariable(_ name: String, value: String) {
        _setCustomVariable(value, name)
    }
    
    /// Sets a custom variable with the specified name and value
    ///
    /// - Parameters:
    ///   - name: The name of the custom variable to set.
    ///   - value: The value to associate with the variable.
    /// If `key` already exists,
    ///     `value` replaces the existing associated value. If `key` isn’t already a key of the
    ///     dictionary, the `(key, value)` pair is added.
    ///
    ///This method allows setting a custom variable where the associated value is of type `NSNumber`.
    ///
    @objc(setCustomVariable:numValue:)
    static func setCustomVariable(_ name: String, value: NSNumber) {
        _setCustomVariable(value, name)
    }
    
    /// Sets a custom variable with the specified name and value.
    ///
    /// - Parameters:
    ///   - name: The name of the custom variable to set.
    ///   - value: The value to associate with the variable, which is of a `Numeric` type (e.g., `Int`, `Double`).
    ///            If the `name` already exists, `value` replaces the existing associated value. If `name`
    ///            isn’t already a key in the dictionary, the `(name, value)` pair is added.
    ///
    /// This method provides a flexible way to associate numeric values with a custom variable name.
    ///
    static func setCustomVariable<T: Numeric>(_ name: String, value: T) {
        _setCustomVariable(value, name)
    }
    
    /// Sets a custom variable with the specified name and value
    ///
    /// - Parameters:
    ///   - name: The name of the custom variable to set.
    ///   - value: The value to associate with the variable.
    /// If `key` already exists,
    ///     `value` replaces the existing associated value. If `key` isn’t already a key of the
    ///     dictionary, the `(key, value)` pair is added.
    ///
    ///This method allows setting a custom variable where the associated value is of type `Bool`.
    ///
    @objc(setCustomVariable:boolValue:)
    static func setCustomVariable(_ name: String, value: Bool) {
        _setCustomVariable(value, name)
    }
    
    /// Sets multiple custom variables based on the provided dictionary.
    ///
    /// - Parameter variables: A dictionary containing key-value pairs where
    ///
    @objc
    static func setCustomVariables(_ variables : [String: String] ) {
        for (name, value) in variables {
            self.setCustomVariable(name, value: value)
        }
    }
    
    /// Retrieves the value of a custom variable by its name.
    ///
    /// - Parameter name: The name of the custom variable to retrieve.
    ///
    /// - Returns: The value associated with the custom variable, or `nil`
    ///   if the variable does not exist ..
    ///
    @objc
    static func getCustomVariable(_ name: String) -> String?{
        return _getCustomVariable(name)
    }
    
    /// Retrieves custom variables in the form of a dictionary of key-value pairs.
    ///
    /// - Returns: A dictionary where the keys are the  names and the values are their corresponding string values.
    ///
    @objc
    static func getCustomVariables() -> [String: String] {
        
        guard enableAllTracking else{
            return [:]
        }
        
        var stringDict: [String: String] = [:]
        for (key, _) in self.metrics {
            if let stringValue = getCustomVariable(key){
                stringDict[key] = stringValue
            }
        }
        return stringDict
    }
    
    /// Clear custom variable for name from the dictionary.
    ///
    /// - Parameter name: The name of the custom variable to clear.
    ///
    @objc
    static func clearCustomVariable(_ name : String){
        guard enableAllTracking else{
            return
        }
        
        self.metrics.removeValue(forKey: name)
    }
    
    /// Clears all custom variables from the dictionary.
    ///
    /// This function resets the  dictionary to an empty state, removing all previously set custom variables.
    ///
    @objc
    static func clearAllCustomVariables() {
        
        guard enableAllTracking else{
            return
        }
        
        self.metrics = [:]
    }
}

// MARK: - Network Capture
public extension BlueTriangle {
    internal static func timerDidStart(_ type: BTTimer.TimerType, page: Page, startTime: TimeInterval, isGroupTimer: Bool = false) {
        guard case .main = type else {
            return
        }

        Task {
            await getNetworkRequestCapture()?.start(page: page, startTime: startTime, isGroupTimer: isGroupTimer)
        }
    }
    /// Returns a timer for network capture.
    static func startRequestTimer() -> InternalTimer? {
        guard shouldCaptureRequests || shouldCheckoutTracking else {
            return nil
        }
        var timer = internalTimerFactory()
        timer.start()
        return timer
    }
    
    static func setGroupName(_ groupName: String) {
        if configuration.enableGrouping {
            BlueTriangle.groupTimer.setGroupName(groupName)
        }
    }
    
    static func setNewGroup(_ newGroup: String) {
        if configuration.enableGrouping {
            BlueTriangle.groupTimer.setNewGroup(newGroup)
        }
    }
    
    internal static func updateCaptureRequest(pageName : String, startTime: Millisecond){
        Task {
            await getNetworkRequestCapture()?.update(pageName: pageName, startTime: startTime)
        }
    }
    
    static func captureRequest(timer: InternalTimer, response: URLResponse?) {
        Task {
            await getNetworkRequestCapture()?.collect(timer: timer, response: response)
            await reportAutoCheckoutFor(CapturedRequest(timer: timer, relativeTo: 0, response: response))
        }
    }

    internal static func captureRequest(timer: InternalTimer, response: CustomResponse) {
        Task {
            await getNetworkRequestCapture()?.collect(timer: timer, response: response)
            await reportAutoCheckoutFor(CapturedRequest(timer: timer, relativeTo: 0, response: response))
        }
    }

    /// Captures a network request.
    /// - Parameters:
    ///   - timer: The request timer.
    ///   - tuple: The asynchronously-delivered tuple containing the request contents as a Data instance and a URLResponse.
    static func captureRequest(timer: InternalTimer, tuple: (Data, URLResponse)) {
        Task {
            await getNetworkRequestCapture()?.collect(timer: timer, response: tuple.1)
            await reportAutoCheckoutFor(CapturedRequest(timer: timer, relativeTo: 0, response: tuple.1))
        }
    }
    
    static func captureRequest(timer: InternalTimer, request : URLRequest, error: Error?) {
        Task {
            await getNetworkRequestCapture()?.collect(timer: timer, request: request, error: error)
            await reportAutoCheckoutFor(CapturedRequest(timer: timer, relativeTo: 0, request: request, error: error))
        }
    }
    /// Captures a network request.
    /// - Parameter metrics: An object encapsulating the metrics for a session task.
    static func captureRequest(metrics: URLSessionTaskMetrics, error : Error?) {
        Task {
            await getNetworkRequestCapture()?.collect(metrics: metrics, error: error)
            await reportAutoCheckoutFor(CapturedRequest(metrics: metrics, relativeTo: 0, error: error))
        }
    }
    
    private static func reportAutoCheckoutFor(_ request: CapturedRequest) async {
        await BlueTriangle.checkoutEvent.onCheckoutEvent(NetworkCheckoutEvent(url: request.url, statusCode: request.statusCode))
    }
    
    internal static func startGroupTimerRequest(page : Page, startTime : Millisecond) async {
        await getGroupRequestCapture()?.start(page: page, startTime: startTime)
    }
    
    internal static func captureGroupRequest(startTime : Millisecond, endTime: Millisecond, groupStartTime: Millisecond, response: CustomPageResponse) async {
        await getGroupRequestCapture()?.collect(startTime: startTime, endTime: endTime, groupStartTime: groupStartTime, response: response)
    }
    
    internal static func uploadGroupedViewCollectedRequests() async {
        await getGroupRequestCapture()?.uploadCollectedRequests()
    }
    
    //Actions
    internal static func startActionTimerRequest(page : Page, startTime : Millisecond) async{
        await capturedActionsViewRequestCollector?.start(page: page, startTime: startTime)
    }
    
    internal static func captureActionRequest(startTime : Millisecond, endTime: Millisecond, groupStartTime: Millisecond, action: UserAction) async {
            await capturedActionsViewRequestCollector?.collect(startTime: startTime, endTime: endTime, groupStartTime: groupStartTime, action: action)
    }
    
    internal static func uploadActionViewCollectedRequests() async{
        await capturedActionsViewRequestCollector?.uploadCollectedRequests()
    }
}

// MARK: - Error Tracking
public extension BlueTriangle {

    /// Uploads a crash timer and a corresponding report to Blue Triangle for processing.
    /// - Parameter error: The error to upload.
    static func logError<E: Error>(
        _ error: E,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        nsExeptionReporter?.uploadError(error, file: file, function: function, line: line)
    }
}

// MARK: - Crash Reporting
extension BlueTriangle {
    static func configureCrashTracking(with crashConfiguration: CrashReportConfiguration) {
        nsExeptionReporter = CrashReportManager(crashReportPersistence: CrashReportPersistence.self,
                                                logger: logger,
                                                uploader: uploader,
                                                session: {session()})
        
        CrashReportPersistence.configureCrashHandling(configuration: crashConfiguration)
    }
    
    
    public static func startCrashTracking() {
#if DEBUG
        SignalHandler.enableCrashTracking(withApp_version: Version.number, debug_log: true, bttSessionID: "\(sessionID)")
#else
        SignalHandler.enableCrashTracking(withApp_version: Version.number, debug_log: false, bttSessionID: "\(sessionID)")
#endif
    }
    
    static func configureSignalCrash(with crashConfiguration: CrashReportConfiguration, debugLog : Bool) {
        SignalHandler.enableCrashTracking(withApp_version: Version.number, debug_log: debugLog, bttSessionID: "\(sessionID)")
        signalCrashReporter = BTSignalCrashReporter(directory: SignalHandler.reportsFolderPath(), logger: logger,
                                                    uploader: uploader,
                                                    session: {session()})
        signalCrashReporter?.configureSignalCrashHandling(configuration: crashConfiguration)
    }

    /// Saves an exception to upload to the Blue Triangle portal on next launch.
    ///
    /// Use this method to store exceptions caught by other exception handlers.
    ///
    /// - Parameter exception: The exception to upload.
    public static func storeException(exception: NSException) {
        if let session = session() {
            let pageName = BlueTriangle.recentTimer()?.getPageName()
            let segment = BlueTriangle.recentTimer()?.getTrafficSegment() ?? session.trafficSegmentName
            let pageType = BlueTriangle.recentTimer()?.page.pageType ?? session.pageType
            let crashReport = CrashReport(sessionID: sessionID, exception: exception, pageName: pageName, segment: segment, pageType: pageType)
            CrashReportPersistence.save(crashReport)
        }
    }
}

//MARK: - ANR Tracking
extension BlueTriangle{
    static func configureANRTracking(with enabled: Bool, enableStackTrace : Bool, interval: TimeInterval){
        if enabled{
            self.anrWatchDog = ANRWatchDog(
                mainThreadObserver: MainThreadObserver.live,
                session: {session()},
                uploader: configuration.uploaderConfiguration.makeUploader(logger: logger, failureHandler: RequestFailureHandler(
                    file: .requests,
                    logger: logger)),
                logger: BlueTriangle.logger)
            
            self.anrWatchDog?.errorTriggerInterval = interval
            self.anrWatchDog?.enableStackTrace = enableStackTrace
            if enabled {
                MainThreadObserver.live.setUpLogger(logger)
                MainThreadObserver.live.start()
                self.anrWatchDog?.start()
            }
        }
    }
}

// MARK: - Screen Tracking
extension BlueTriangle{
    static func configureScreenTracking(with enabled: Bool){
        screenTracker = BTTScreenLifecycleTracker()
        screenTracker?.setLifecycleTracker(enabled)
        screenTracker?.setUpLogger(logger)
        
#if os(iOS)
        BTTWebViewTracker.shouldCaptureRequests = shouldCaptureRequests
        BTTWebViewTracker.logger = logger
        if enabled {
            UIViewController.setUp()
        }
#endif
    }
}

// MARK: - Network State
extension BlueTriangle{
    static func configureMonitoringNetworkState(with enabled: Bool){
        if enabled {
            networkStateMonitor = NetworkStateMonitor.init(logger)
        }
    }
}


// MARK: - LaunchTime
extension BlueTriangle{
    
    static func configureLaunchTime(with enabled: Bool){
        if enabled{
            let launchMonitor = LaunchTimeMonitor(logger: logger)
            launchTimeReporter = LaunchTimeReporter(using: {session()},
                                                    uploader: configuration.uploaderConfiguration.makeUploader(logger: logger, failureHandler: RequestFailureHandler(
                                                        file: .requests,
                                                        logger: logger)),
                                                    logger: BlueTriangle.logger,
                                                    monitor: launchMonitor)
            
        }
    }
}

//MARK: - Memory Warning
extension BlueTriangle{
    static func configureMemoryWarning(with enabled: Bool){
        if enabled{
#if os(iOS)
            memoryWarningWatchDog = MemoryWarningWatchDog(
                session: {session()},
                uploader: configuration.uploaderConfiguration.makeUploader(logger: logger, failureHandler: RequestFailureHandler(
                    file: .requests,
                    logger: logger)),
                logger: BlueTriangle.logger)
            self.memoryWarningWatchDog?.start()
#endif
        }
    }
}

//MARK: - Session Expiry
extension BlueTriangle{
    
    /// The session manager is responsible for handling session-related functionality,
    /// such as timing and lifecycle management.
    ///
    /// - Parameters:
    ///   - expiry: The session expiry duration in milliseconds.
    ///
    /// - Behavior:
    ///   - If `enableAllTracking` is true, the SDK uses `SessionManager` to handle
    ///     session management for the active tracking mode.
    ///   - If `enableAllTracking` is false, the SDK uses `DisableModeSessionManager` to manage
    ///     session activity while tracking is disabled.
    ///   - If the correct session manager is already set, no action is taken to avoid redundant reconfiguration.
    ///
    ///
    static func configureSessionManager(forModeWithExpiry expiry: Millisecond){
        if self.enableAllTracking{
            if let _ = sessionManager as? SessionManager {
                return
            }
            sessionManager?.stop()
            sessionManager = enabledModeSessionManager
            sessionManager?.start(with: expiry)
        }else{
            if let _ = sessionManager as? DisableModeSessionManager {
                return
            }
            sessionManager?.stop()
            sessionManager = disableModeSessionManager
            sessionManager?.start(with: expiry)
        }
    }
}

// MARK: - Test Support
extension BlueTriangle {
    @objc
    static func reset() {
        lock.sync {
            configuration = BlueTriangleConfiguration()
            initialized = false
        }
    }
}

// MARK: - Remote config
extension BlueTriangle {
   
    internal static func updateNetworkSampleRate(_ rate : Double) {
        configuration.networkSampleRate = rate
    }
    
    internal static func updateIgnoreVcs(_ vcs : Set<String>?) {
        if let vcs = vcs{
            configuration.ignoreViewControllers = vcs
        }
    }
    
    internal static func updateGrouping(_ isEnable : Bool, idleTime : Double) {
        configuration.enableGrouping = isEnable
        configuration.groupingIdleTime = idleTime
    }
    
    internal static func updateScreenTracking(_ enabled : Bool) {
        configuration.enableScreenTracking = enabled
        screenTracker?.setLifecycleTracker(enabled)
#if os(iOS)
        if enabled {
            UIViewController.setUp()
        } else {
            UIViewController.removeSetUp()
        }
#endif
    }
    
    internal static func updateCaptureRequests() {
        if let sessionData = sessionData(){
            shouldCaptureRequests = sessionData.shouldNetworkCapture
            _session?.wcd = shouldCaptureRequests ? 1 : 0
            if shouldCaptureRequests {
                if getNetworkRequestCapture() == nil {
                    setNetworkRequestCapture(makeCapturedRequestCollector())
                }
            } else {
                setNetworkRequestCapture(makeCapturedRequestCollector())
            }
            
            if shouldCaptureRequests {
                if getGroupRequestCapture() == nil {
                    setGroupRequestCapture(makeCapturedGroupRequestCollector())
                }
            } else {
                setGroupRequestCapture(makeCapturedGroupRequestCollector())
            }
            
#if os(iOS)
            BTTWebViewTracker.shouldCaptureRequests = shouldCaptureRequests
#endif
        }
    }
    
    internal static func updateLaunchTime(_ enabled : Bool) {
        configuration.enableLaunchTime = enabled
        if enabled {
            self.startLaunchTime()
        } else {
            self.stopLaunchTime()
        }
    }
    
    internal static func updateTrackingNetworkState(_ enabled : Bool) {
        configuration.enableTrackingNetworkState = enabled
        if enabled {
            self.startNetworkStatus()
        } else {
            self.stopNetworkStatus()
        }
    }
    
    internal static func updateCrashTracking(_ enabled : Bool) {
        configuration.crashTracking = enabled ? .nsException : .none
        if enabled {
            self.startNsAndSignalCrashTracking()
        } else {
            self.stopNsAndSignalCrashTracking()
        }
    }
    
    internal static func updateAnrMonitoring(_ enabled : Bool) {
        configuration.ANRMonitoring = enabled
        if enabled {
            self.startANR()
        } else {
            self.stopANR()
        }
    }
    
    internal static func updateMemoryWarning(_ enabled : Bool) {
        configuration.enableMemoryWarning = enabled
        if enabled {
            self.startMemoryWarning()
        } else {
            self.stopMemoryWarning()
        }
    }

    internal static func updateWebViewStitching(_ enabled : Bool) {
        configuration.enableWebViewStitching = enabled
#if os(iOS)
        BTTWebViewTracker.enableWebViewStitching = enabled
#endif
    }
    
    internal static func updateGroupingTapDetection(_ enabled : Bool) {
        configuration.enableGroupingTapDetection = enabled
    }
    
    internal static func updateCheckoutTracking(_ enabled: Bool) {
        configuration.checkoutTrackingEnabled = enabled
    }

    internal static func updateCheckoutClassNames(_ classNames: [String]) {
        configuration.checkoutClassName = classNames
    }

    internal static func updateCheckoutURL(_ url: String) {
        configuration.checkoutURL = url
    }

    internal static func updateCheckoutAmount(_ amount: Double) {
        configuration.checkoutAmount = amount
    }

    internal static func updateCheckoutCartCount(_ count: Int) {
        configuration.checkoutCartCount = count
    }

    internal static func updateCheckoutCartCountCheckout(_ count: Int) {
        configuration.checkoutCartCountCheckout = count
    }

    internal static func updateCheckoutOrderNumber(_ orderNumber: String) {
        configuration.checkoutOrderNumber = orderNumber
    }

    internal static func updateCheckoutTimeValue(_ timeValue: Int) {
        configuration.checkoutTimeValue = timeValue
    }
}
