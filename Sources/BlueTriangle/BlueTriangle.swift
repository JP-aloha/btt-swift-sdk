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

final class Store: @unchecked Sendable {
    private let sessionLock = NSLock()
    private let configLock = NSLock()
    private let initLock = NSLock()
    private let allTrackingLock = NSLock()
    private let timerLock = NSLock()
    private let sessionManagerlock = NSLock()
    private let shouldGroupedCapturelock = NSLock()
    private let shouldNetworkCapturelock = NSLock()
    
    private var initialized = false
    private var enableAllTracking: Bool = true
    private var shouldGroupedCaptureRequests: Bool = false
    private var shouldNetworkCaptureRequests: Bool = false
    private var activeTimers = [BTTimer]()
    private var configuration = BlueTriangleConfiguration()
    private var sessionManager : SessionManagerProtocol?
    private lazy var session: Session? = {
        configuration.makeSession()
    }()
    
    internal lazy var groupTimer : BTTimerGroupManager = {
        BTTimerGroupManager(logger: logger)
    }()
    
    internal lazy var logger: Logging = {
        configuration.makeLogger()
    }()
    
    internal lazy var configRepo: BTTConfigurationRepo = {
        BTTConfigurationRepo(BTTRemoteConfig.defaultConfig)
    }()
    
    internal lazy var uploader: Uploading = {
        configuration.uploaderConfiguration.makeUploader(
            logger: logger,
            failureHandler: RequestFailureHandler(
                file: .requests,
                logger: logger))
    }()
    
    internal func isInitialized() -> Bool {
        initLock.sync {
            return initialized
        }
    }
    
    internal func setInitialized(_ initialized: Bool) {
        initLock.sync {
            self.initialized = initialized
        }
    }
    
    internal func addActiveTimer(_ timer : BTTimer){
        timerLock.sync { activeTimers.append(timer)}
    }
    
    internal func removeActiveTimer(_ timer: BTTimer) {
        timerLock.sync {
            if let index = activeTimers.firstIndex(of: timer) {
                activeTimers.remove(at: index)
            }
        }
    }

    internal func recentTimer() -> BTTimer?{
        timerLock.sync {
            let timer = activeTimers.last
            return timer
        }
    }
    
    internal func getAllTrackingEnabled() -> Bool {
        allTrackingLock.sync {
            return enableAllTracking
        }
    }
    
    internal func setAllTrackingEnabled(_ enabled: Bool) {
        allTrackingLock.sync {
            self.enableAllTracking = enabled
        }
    }
    
    internal func getShouldGroupedCaptureRequests() -> Bool {
        shouldGroupedCapturelock.sync {
            return shouldGroupedCaptureRequests
        }
    }
    
    internal func setShouldGroupedCaptureRequests(_ enabled: Bool) {
        shouldGroupedCapturelock.sync {
            self.shouldGroupedCaptureRequests = enabled
        }
    }
    
    internal func getShouldNetworkCaptureRequests() -> Bool {
        shouldNetworkCapturelock.sync {
            return shouldNetworkCaptureRequests
        }
    }
    
    internal func setShouldNetworkCaptureRequests(_ enabled: Bool) {
        shouldNetworkCapturelock.sync {
            self.shouldNetworkCaptureRequests = enabled
        }
    }
    
    internal func getConfiguration() -> BlueTriangleConfiguration {
        configLock.sync {
            return configuration
        }
    }
    
    internal func setConfiguration(_ configuration: BlueTriangleConfiguration) {
        configLock.sync {
            self.configuration = configuration
        }
    }
    
    internal func getSession() -> Session? {
        sessionLock.sync {
            return session
        }
    }
    
    internal func setSession(_ session: Session?) {
        sessionLock.sync {
            self.session = session
        }
    }
    
    internal func makeSession() {
        sessionLock.sync {
            self.session = configuration.makeSession()
        }
    }
    
    internal func shutdownSession() {
        sessionLock.sync {
            self.session = nil
        }
    }
    
    internal func updateSessionId(_ sessionId : Identifier) {
        sessionLock.sync {
            self.session?.sessionID = sessionId
        }
    }
    
    internal func setSessionManager(_ sessionManager: SessionManagerProtocol?) {
        sessionManagerlock.sync {
            self.sessionManager = sessionManager
        }
    }
    
    internal func getSessionManager() -> SessionManagerProtocol?{
        sessionManagerlock.sync {
            self.sessionManager
        }
    }
    
    internal lazy var timerFactory: (Page, BTTimer.TimerType, Bool) -> BTTimer = {
        configuration.timerConfiguration.makeTimerFactory(
            logger: logger,
            performanceMonitorFactory: configuration.makePerformanceMonitorFactory())
    }()
    
    internal lazy var internalTimerFactory: () -> InternalTimer = {
        configuration.internalTimerConfiguration.makeTimerFactory(logger: logger)
    }()
    
    internal lazy var payloadCache : PayloadCacheProtocol = {
        PayloadCache.init( configuration.cacheMemoryLimit,
                           expiry: configuration.cacheExpiryDuration)
    }()
    
    //Screen Tracking
    private var screenTracker: BTTScreenLifecycleTracker?
    private let screenTrackerLock = NSLock()
    internal func getLifecycleTracker() -> BTTScreenLifecycleTracker? {
        screenTrackerLock.sync {
            return screenTracker
        }
    }
    
    internal func makeLifecycleTracker() {
        screenTrackerLock.sync {
            screenTracker = BTTScreenLifecycleTracker(logger, enableLifecycleTracker: configuration.enableScreenTracking)
        }
    }
    
    internal func shutdownLifecycleTracker() {
        screenTrackerLock.sync {
            screenTracker = nil
        }
    }
    
    private var clarityConnector: ClaritySessionConnector?
    private let clarityConnectorLock = NSLock()

    internal func getClarityConnector()-> ClaritySessionConnector? {
        clarityConnectorLock.sync {
            clarityConnector
        }
    }
    
    internal func shutdownClarityConnector() {
        clarityConnectorLock.sync {
            clarityConnector = nil
        }
    }
    
    internal func makeClarityConnector() {
        clarityConnectorLock.sync {
            clarityConnector = ClaritySessionConnector(logger: logger)
        }
    }
    
    internal func loadConfigAllTracking() {
        self.setAllTrackingEnabled(configRepo.isEnableAllTracking())
    }
    
    //Net State
    private var networkStateMonitor: NetworkStateMonitorProtocol?
    private let networkStateMonitorLock = NSLock()
    internal func getNetworkStateMonitor() -> NetworkStateMonitorProtocol? {
        networkStateMonitorLock.sync {
            networkStateMonitor
        }
    }
    
    internal func makeNetworkStateMonitor() {
        networkStateMonitorLock.sync {
            networkStateMonitor = NetworkStateMonitor.init(logger)
        }
    }
    
    internal func shutdownNetworkStateMonitor() {
        networkStateMonitorLock.sync {
            networkStateMonitor = nil
        }
    }
    //Launch Time
    private var launchTimeReporter : LaunchTimeReporter?
    private let launchTimeReporterLock = NSLock()
    internal func getLaunchTimeReporter() -> LaunchTimeReporter? {
        launchTimeReporterLock.sync {
            launchTimeReporter
        }
    }
    
    internal func makeLaunchTimeMonitor() {
        launchTimeReporterLock.sync {
            let launchMonitor = LaunchTimeMonitor(logger: logger)
            launchTimeReporter = LaunchTimeReporter(using: {self.getSession()},
                                                    uploader: getConfiguration().uploaderConfiguration.makeUploader(logger: logger, failureHandler: RequestFailureHandler(
                                                        file: .requests,
                                                        logger: logger)),
                                                    logger: logger,
                                                    monitor: launchMonitor)
        }
        
    }
    
    internal func shutdownLaunchTimeMonitor() {
        launchTimeReporterLock.sync {
            launchTimeReporter = nil
        }
    }
    
    private var nsExeptionReporter: CrashReportManaging?
    private var signalCrashReporter: BTSignalCrashReporter?
    private let nsExeptionReporterLock = NSLock()
    private let signalCrashReporterLock = NSLock()

    internal func getNsExeptionReporter() -> CrashReportManaging? {
        nsExeptionReporterLock.sync {
            nsExeptionReporter
        }
    }
    
    internal func makeNsExeptionReporter() {
        nsExeptionReporterLock.sync {
            nsExeptionReporter = CrashReportManager(crashReportPersistence: CrashReportPersistence.self,
                                                    logger: logger,
                                                    uploader: uploader,
                                                    session: {self.getSession()})
        }
        
    }
    
    internal func shutdownNsExeptionReporter() {
        nsExeptionReporterLock.sync {
            nsExeptionReporter = nil
        }
    }
    
    internal func getSignalCrashReporter() -> BTSignalCrashReporter? {
        signalCrashReporterLock.sync {
            signalCrashReporter
        }
    }
    
    internal func makeSignalCrashReporter() {
        signalCrashReporterLock.sync {
            signalCrashReporter = BTSignalCrashReporter(directory: SignalHandler.reportsFolderPath(), logger: logger,
                                                        uploader: uploader,
                                                        session: {self.getSession()})
        }
    }
    
    internal func shutdownSignalCrashReporter() {
        signalCrashReporterLock.sync {
            signalCrashReporter = nil
        }
    }
    
    //memory
    private var memoryWarningWatchDog : MemoryWarningWatchDog?
    private let memoryWarningLock = NSLock()
    internal func getMemoryWarningWatchDog() -> MemoryWarningWatchDog? {
        memoryWarningLock.sync {
            memoryWarningWatchDog
        }
    }
    
    internal func makeMemoryWarningWatchDog() {
        memoryWarningLock.sync {
            memoryWarningWatchDog = MemoryWarningWatchDog(
                session: {self.getSession()},
                uploader: getConfiguration().uploaderConfiguration.makeUploader(logger: logger, failureHandler: RequestFailureHandler(
                    file: .requests,
                    logger: logger)),
                logger: logger)
        }
        
    }
    
    internal func shutdownMemoryWarningWatchDog() {
        memoryWarningLock.sync {
            memoryWarningWatchDog = nil
        }
    }
    
    private var anrWatchDog : ANRWatchDog?
    private let anrWatchDogLock = NSLock()

    internal func getANRWatchDog() -> ANRWatchDog? {
        anrWatchDogLock.sync {
            anrWatchDog
        }
    }
    
    internal func makeANRWatchDog() {
        anrWatchDogLock.sync {
            anrWatchDog = ANRWatchDog(
                mainThreadObserver: MainThreadObserver.live,
                session: {self.getSession()},
                uploader: getConfiguration().uploaderConfiguration.makeUploader(logger: logger, failureHandler: RequestFailureHandler(
                    file: .requests,
                    logger: logger)),
                logger: logger)
        }
    }
    
    internal func shutdownANRWatchDog() {
        anrWatchDogLock.sync {
            anrWatchDog = nil
        }
    }
    
    private var capturedRequestCollector: CapturedRequestCollecting?
    private let capturedRequestLock = NSLock()
    
    func getCapturedGroupedViewRequestCollector() -> CapturedGroupRequestCollecting? {
        capturedRequestLock.sync {
            if let collector = capturedGroupedViewRequestCollector {
                return collector
            }
            let newCollector = makeCapturedGroupRequestCollector()
            capturedGroupedViewRequestCollector = newCollector
            return newCollector
        }
    }
    
    func setCapturedGroupedViewRequestCollector(_ newCollector : CapturedGroupRequestCollecting?) {
        capturedRequestLock.sync {
            capturedGroupedViewRequestCollector = newCollector
        }
    }
    
    internal func makeCapturedGroupRequestCollector() -> CapturedGroupRequestCollecting? {
        if let _ = getSession() ,getShouldGroupedCaptureRequests() {
            let groupCollector = getConfiguration().capturedGroupRequestCollectorConfiguration.makeRequestCollector(
                logger: logger,
                networkCaptureConfiguration: .standard,
                requestBuilder: CapturedRequestBuilder.makeBuilder {self.getSession()},
                uploader: uploader)
            return groupCollector
        } else {
            return nil
        }
    }
    
    private var capturedGroupedViewRequestCollector: CapturedGroupRequestCollecting?
    private let capturedGroupedLock = NSLock()

    func getCapturedRequestCollector() -> CapturedRequestCollecting? {
        capturedGroupedLock.sync {
            if let collector = capturedRequestCollector {
                return collector
            }
            let newCollector = makeCapturedRequestCollector()
            capturedRequestCollector = newCollector
            return newCollector
        }
    }
    
    func setCapturedRequestCollector(_ newCollector : CapturedRequestCollecting?) {
        capturedGroupedLock.sync {
            capturedRequestCollector = newCollector
        }
    }
    
    internal func makeCapturedRequestCollector() -> CapturedRequestCollecting? {
        if let _ = getSession(), getShouldNetworkCaptureRequests(), getConfiguration().enableGrouping {
            let collector = getConfiguration().capturedRequestCollectorConfiguration.makeRequestCollector(
                logger: logger,
                networkCaptureConfiguration: .standard,
                requestBuilder: CapturedRequestBuilder.makeBuilder {self.getSession()},
                uploader: uploader)
            
            Task {
                await collector.configure()
            }
            return collector
        } else {
            return nil
        }
    }
    
    internal lazy var disableModeSessionManager : SessionManagerProtocol = {
        let configFetcher  =  BTTConfigurationFetcher(logger: logger)
        let configSyncer = BTTStoredConfigSyncer(configRepo: configRepo, logger: logger)
        let updater  =  BTTConfigurationUpdater(configFetcher: configFetcher, configRepo: configRepo, logger: logger, configAck: nil)
        return DisableModeSessionManager(logger, configRepo, updater, configSyncer)
    }()
    
    internal lazy var enabledModeSessionManager : SessionManagerProtocol = {
        let configFetcher  =  BTTConfigurationFetcher(logger: logger)
        let configSyncer = BTTStoredConfigSyncer(configRepo: configRepo, logger: logger)
        let configAck  =  RemoteConfigAckReporter(logger: logger, uploader: uploader)
        let updater  =  BTTConfigurationUpdater(configFetcher: configFetcher, configRepo: configRepo, logger: logger, configAck: configAck)
        return SessionManager(logger, configRepo, updater, configSyncer)
    }()
}


/// The entry point for interacting with the Blue Triangle SDK.
final public class BlueTriangle: NSObject {
    private static let lock = NSLock()
    private static let store = Store()

    internal static var configuration : BlueTriangleConfiguration {
        get { store.getConfiguration()}
        set { store.setConfiguration(newValue)}
    }
    
    internal static func getScreenTracker() async -> BTTScreenLifecycleTracker?{
        store.getLifecycleTracker()
    }
    
    internal static func networkStateMonitor() async -> NetworkStateMonitorProtocol?{
         store.getNetworkStateMonitor()
    }

    private static var sessionManager : SessionManagerProtocol?{
        get { store.getSessionManager() }
        set { store.setSessionManager(newValue) }
    }
    
    internal static var isGroupingEnabled : Bool {
        return configuration.enableGrouping && store.getShouldGroupedCaptureRequests()
    }
    
    internal static var enableAllTracking: Bool {
        get { return store.getAllTrackingEnabled()  }
        set { store.setAllTrackingEnabled(newValue) }
    }
    
    internal static var shouldCaptureRequests: Bool {
        get { return store.getShouldGroupedCaptureRequests()  }
        set { store.setShouldNetworkCaptureRequests(newValue) }
    }

    internal static func addActiveTimer(_ timer : BTTimer){
        store.addActiveTimer(timer)
    }
    
    internal static func removeActiveTimer(_ timer: BTTimer) {
        store.removeActiveTimer(timer)
    }
    
    internal static func recentTimer() -> BTTimer?{
        let timer = store.recentTimer()
        return timer
    }
    
    private static var _session: Session? {
        get { store.getSession()}
        set { store.setSession(newValue) }
    }
    
    internal static func session() -> Session? {
        return _session
    }
    
    internal static func sessionData() -> SessionData? {
        return store.getSessionManager()?.getSessionData()
    }
    
    private static var logger: Logging {
        get { store.logger }
        set { store.logger = newValue }
    }

    internal static var timerFactory: (Page, BTTimer.TimerType, Bool) -> BTTimer {
        get { store.timerFactory }
        set { store.timerFactory = newValue }
    }

    internal static var internalTimerFactory: () -> InternalTimer {
        get { store.internalTimerFactory }
        set { store.internalTimerFactory = newValue }
    }
    
    /// A Boolean value indicating  whether the SDK has been successfully configured and initialized.
    ///
    /// - `true`: The SDK has been configured and is ready to function. This means
    ///           that all necessary setup steps have been completed.
    /// - `false`: The SDK has not been configured. In this state, the SDK will not
    ///            function correctly, including the ability to fetch updates for the
    ///            enable/disable state via the Remote Configuration Updater.
    ///
    public static func isInitialized() async -> Bool {
        return initialized
    }
    
    public static var initialized: Bool {
        get { store.isInitialized() }
        set { store.setInitialized(newValue) }
    }
    
    private static func getNetworkRequestCapture() -> CapturedRequestCollecting? {
        return store.getCapturedRequestCollector()
    }
    
    private static func setNetworkRequestCapture(_ requestCapture :CapturedRequestCollecting?)  {
        store.setCapturedRequestCollector(requestCapture)
    }
    
    private static func setGroupRequestCapture(_ groupCapture :CapturedGroupRequestCollecting?) {
        store.setCapturedGroupedViewRequestCollector(groupCapture)
    }
    
    internal static func getGroupRequestCapture() -> CapturedGroupRequestCollecting? {
        return  store.getCapturedGroupedViewRequestCollector()
    }
    
    //Cache components
    internal static var payloadCache : PayloadCacheProtocol {
        get { store.payloadCache }
        set { store.payloadCache = newValue }
    }
    
    /// Blue Triangle Technologies-assigned site ID.
    @objc public static var siteID: String {
        lock.sync { session()?.siteID ?? configuration.siteID }
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

    /// A/B testing identifier.
    @objc public static var abTestID: String {
        get {
            lock.sync { session()?.abTestID ?? configuration.abTestID}
        }
        set {
            lock.sync { _session?.abTestID = newValue }
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
    @objc public static var campaignMedium: String {
        get {
            lock.sync { session()?.campaignMedium ?? ""}
        }
        set {
            lock.sync { _session?.campaignMedium = newValue}
        }
    }

    /// Campaign name.
    @objc public static var campaignName: String {
        get {
            lock.sync { session()?.campaignName ?? "" }
        }
        set {
            lock.sync { _session?.campaignName = newValue }
        }
    }

    /// Campaign source.
    @objc public static var campaignSource: String {
        get {
            lock.sync { session()?.campaignSource ?? "" }
        }
        set {
            lock.sync { _session?.campaignSource = newValue}
        }
    }

    /// Data center.
    @objc public static var dataCenter: String {
        get {
            lock.sync { session()?.dataCenter ?? "" }
        }
        set {
            lock.sync { _session?.dataCenter = newValue }
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
    private static func stopClarity() {
        store.shutdownClarityConnector()
        logger.info("BlueTriangle :: Clarity was ended due to SDK disable.")
    }
    
    private static func startClarity() {
        if store.getClarityConnector() == nil{
            store.makeClarityConnector()
        }
        logger.info("BlueTriangle :: Clarity was ended due to SDK disable.")
    }
    
    private static func startSession() {
        if  store.getSession() == nil{
            store.makeSession()
        }
        logger.info("BlueTriangle :: Session has started.")
    }
    
    // Ends the current session and logs the action
    private static func endSession() {
        store.shutdownSession()
        logger.info("BlueTriangle :: Session was ended due to SDK disable.")
    }
    
    // Starts HTTP network capture and updates capture requests
    private static func startHttpNetworkCapture() {
        self.updateCaptureRequests()
        logger.info("BlueTriangle :: HTTP network capture has started.")
    }
    
    // Stops HTTP network capture and clears captured requests
    private static func stopHttpNetworkCapture() {
         self.setNetworkRequestCapture(nil)
        logger.info("BlueTriangle :: HTTP network capture was stopped due to SDK disable.")
    }
    
    // Starts HTTP network capture and updates capture requests
    private static func startHttpGroupedChildCapture() {
         self.updateGroupedViewCaptureRequest()
        logger.info("BlueTriangle :: Grouped child view capture has started.")
    }
    
    // Stops HTTP network capture and clears captured requests
    private static func stopHttpGroupedChildCapture() {
         self.setGroupRequestCapture(nil)
        logger.info("BlueTriangle :: Grouped child view capture was stopped due to SDK disable.")
    }
    
    // Starts launch time collection and reporting if not already configured
    private static func startLaunchTime() {
        if  store.getLaunchTimeReporter() == nil{
            configureLaunchTime(with: configuration.enableLaunchTime)
        }
        logger.info("BlueTriangle :: Launch time collection and reporting has started.")
    }
    
    // Stops launch time collection and reporting
    private static func stopLaunchTime() {
         store.getLaunchTimeReporter()?.stop()
         store.shutdownLaunchTimeMonitor()
        logger.info("BlueTriangle :: Launch time collection and reporting were stopped due to SDK disable.")
    }
    
    // Starts crash tracking for both exceptions and signals
    private static func startNsAndSignalCrashTracking() {
        if let crashConfig = configuration.crashTracking.configuration {
            if  store.getNsExeptionReporter() == nil{
                configureCrashTracking(with: crashConfig)
            }
            
            if store.getSignalCrashReporter() == nil{
                configureSignalCrash(with: crashConfig, debugLog: configuration.enableDebugLogging)
            }
        }
        logger.info("BlueTriangle :: Crash tracking has started.")
    }
    
    // Stops crash tracking for both exceptions and signals
    private static func stopNsAndSignalCrashTracking() {
        store.getNsExeptionReporter()?.stop()
        store.shutdownNsExeptionReporter()
        store.getSignalCrashReporter()?.stop()
        store.shutdownSignalCrashReporter()
        logger.info("BlueTriangle :: Crash tracking was stopped due to SDK disable.")
    }
    
    // Starts memory warning tracking if not already configured
    private static func startMemoryWarning() {
        if store.getMemoryWarningWatchDog() == nil {
            configureMemoryWarning(with: configuration.enableMemoryWarning)
        }
        logger.info("BlueTriangle :: Memory warning tracking has started.")
    }
    
    // Stops memory warning tracking
    private static func stopMemoryWarning() {
        store.getMemoryWarningWatchDog()?.stop()
        store.shutdownMemoryWarningWatchDog()
        logger.info("BlueTriangle :: Memory warning tracking was stopped due to SDK disable.")
    }
    
    // Starts ANR tracking if not already configured
    private static func startANR() {
        if store.getANRWatchDog() == nil{
             configureANRTracking(with: configuration.ANRMonitoring, enableStackTrace: configuration.ANRStackTrace,
                                       interval: configuration.ANRWarningTimeInterval)
        }
        logger.info("BlueTriangle :: ANR tracking has started.")
    }
    
    // Stops ANR tracking
    private static func stopANR() {
         store.getANRWatchDog()?.stop()
         store.shutdownANRWatchDog()
        logger.info("BlueTriangle :: ANR tracking was stopped due to SDK disable.")
    }
    
    // Starts screen tracking if not already configured
    @MainActor
    private static func startScreenTracking()  {
        if  store.getLifecycleTracker() == nil{
             configureScreenTracking(with: configuration.enableScreenTracking)
        }
        logger.info("BlueTriangle :: Screen tracking has started.")
    }
    
    // Stops screen tracking
    @MainActor
    private static func stopScreenTracking() {
        store.getLifecycleTracker()?.stop()
        store.shutdownLifecycleTracker()
        logger.info("BlueTriangle :: Screen tracking was stopped due to SDK disable.")
    }
    
    // Starts network state tracking if not already configured
    private static func startNetworkStatus() {
        if store.getNetworkStateMonitor() == nil{
             configureMonitoringNetworkState(with: configuration.enableTrackingNetworkState)
        }
        logger.info("BlueTriangle :: Network state tracking has started.")
    }
    
    // Stops network state tracking
    private static func stopNetworkStatus() {
         store.getNetworkStateMonitor()?.stop()
         store.shutdownNetworkStateMonitor()
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
    @MainActor @objc
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
    @MainActor
    internal static func applyAllTrackerState() {
        Device.current.loadDeviceInfo()
        self.store.loadConfigAllTracking()
        self.configureSessionManager(forModeWithExpiry: configuration.sessionExpiryDuration)
        if self.enableAllTracking {
            self.startAllTrackers()
        } else {
            self.stopAllTrackers()
        }
        print("Task finsh")
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
    @MainActor
    private static func startAllTrackers() {
        
        logger.info("BlueTriangle :: SDK is in enabled mode.")
        
        self.startSession()
        self.startClarity()
        self.startScreenTracking()
        self.startHttpNetworkCapture()
        self.startHttpGroupedChildCapture()
        self.startNsAndSignalCrashTracking()
        self.startMemoryWarning()
        self.startANR()
        self.startNetworkStatus()
        self.startLaunchTime()
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
    @MainActor
    private static func stopAllTrackers() {
        logger.info("BlueTriangle :: SDK is in disabled mode.")
        self.endSession()
        self.stopClarity()
        self.stopScreenTracking()
        self.stopHttpNetworkCapture()
        self.stopHttpGroupedChildCapture()
        self.stopNsAndSignalCrashTracking()
        self.stopMemoryWarning()
        self.stopANR()
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
        timerFactory: (@Sendable (Page, BTTimer.TimerType, Bool) -> BTTimer)? = nil,
        shouldCaptureRequests: Bool? = nil,
        internalTimerFactory: (@Sendable () -> InternalTimer)? = nil,
        requestCollector: CapturedRequestCollecting? = nil
    ) {
        lock.sync {
            self.configuration = configuration
            initialized = true
            
            // These are plain synchronous assignments – no concurrency check issue.
            if let session {
                self._session = session
            }
            if let logger {
                self.logger = logger
            }
            if let uploader {
                self.store.uploader = uploader
            }
            if let timerFactory {
                self.timerFactory = timerFactory
            }
            if let internalTimerFactory {
                self.internalTimerFactory = internalTimerFactory
            }
        }
        
        if let shouldCaptureRequests {
            self.store.setShouldNetworkCaptureRequests(shouldCaptureRequests)
        }
        self.setNetworkRequestCapture(requestCollector)
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
    static func makeTimer(page: Page, timerType: BTTimer.TimerType = .main) -> BTTimer {
        let timer = makeTimer(page: page, timerType: timerType, isGroupedTimer: false)
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
    static func startTimer(page: Page, timerType: BTTimer.TimerType = .main) -> BTTimer {
        let timer = startTimer(page: page, timerType: timerType, isGroupedTimer: false)
        return timer
    }

    /// Ends a timer and upload it to Blue Triangle for processing.
    /// - Parameters:
    ///   - timer: The timer to upload.
    ///   - purchaseConfirmation: An object describing a purchase confirmation interaction.
    @objc
    static func endTimer(_ timer: BTTimer, purchaseConfirmation: PurchaseConfirmation? = nil) {
        timer.end()
        store.getClarityConnector()?.refreshClaritySessionUrlCustomVariable()
        
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
            store.uploader.send(request: request)
        }
    }
    
    //Internal Methods
    internal static func makeTimer(page: Page, timerType: BTTimer.TimerType = .main, isGroupedTimer: Bool = false) -> BTTimer {
        lock.lock()
        let timer = timerFactory(page, timerType, isGroupedTimer)
        lock.unlock()
        return timer
    }
    
    internal static func startTimer(page: Page, timerType: BTTimer.TimerType = .main, isGroupedTimer: Bool = false) -> BTTimer {
        let timer = makeTimer(page: page, timerType: timerType, isGroupedTimer: isGroupedTimer)
        timer.start()
        return timer
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
    @Sendable
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
        guard shouldCaptureRequests else {
            return nil
        }
        var timer = internalTimerFactory()
        timer.start()
        return timer
    }
    
    internal static func updateCaptureRequest(pageName : String, startTime: Millisecond){
        Task {
            await getNetworkRequestCapture()?.update(pageName: pageName, startTime: startTime)
        }
    }
    
    static func captureRequest(timer: InternalTimer, response: URLResponse?) {
        Task {
            await getNetworkRequestCapture()?.collect(timer: timer, response: response)
        }
    }

    internal static func captureRequest(timer: InternalTimer, response: CustomResponse) {
        Task {
            await getNetworkRequestCapture()?.collect(timer: timer, response: response)
        }
    }

    /// Captures a network request.
    /// - Parameters:
    ///   - timer: The request timer.
    ///   - tuple: The asynchronously-delivered tuple containing the request contents as a Data instance and a URLResponse.
    static func captureRequest(timer: InternalTimer, tuple: (Data, URLResponse)) {
        Task {
            await getNetworkRequestCapture()?.collect(timer: timer, response: tuple.1)
        }
    }
    
    static func captureRequest(timer: InternalTimer, request : URLRequest, error: Error?) {
        Task {
            await getNetworkRequestCapture()?.collect(timer: timer, request: request, error: error)
        }
    }

    /// Captures a network request.
    /// - Parameter metrics: An object encapsulating the metrics for a session task.
    static func captureRequest(metrics: URLSessionTaskMetrics, error : Error?) {
        Task {
            await getNetworkRequestCapture()?.collect(metrics: metrics, error: error)
        }
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
        store.getNsExeptionReporter()?.uploadError(error, file: file, function: function, line: line)
    }
}

// MARK: - Crash Reporting
extension BlueTriangle {
    static func configureCrashTracking(with crashConfiguration: CrashReportConfiguration) {
         store.makeNsExeptionReporter()
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
        store.makeNsExeptionReporter()
        store.getSignalCrashReporter()?.configureSignalCrashHandling(configuration: crashConfiguration)
    }

    /// Saves an exception to upload to the Blue Triangle portal on next launch.
    ///
    /// Use this method to store exceptions caught by other exception handlers.
    ///
    /// - Parameter exception: The exception to upload.
    public static func storeException(exception: NSException) {
        Task {
            let pageName = BlueTriangle.recentTimer()?.getPageName()
            let crashReport = CrashReport(sessionID: sessionID, exception: exception, pageName: pageName, nativeApp: .empty)
            CrashReportPersistence.save(crashReport)
        }
    }
}

//MARK: - ANR Tracking
extension BlueTriangle{
    static func configureANRTracking(with enabled: Bool, enableStackTrace : Bool, interval: TimeInterval) {
        if enabled{
             store.makeANRWatchDog()
             store.getANRWatchDog()?.errorTriggerInterval = interval
             store.getANRWatchDog()?.enableStackTrace = enableStackTrace
            if enabled {
                MainThreadObserver.live.setUpLogger(logger)
                MainThreadObserver.live.start()
                 store.getANRWatchDog()?.start()
            }
        }
    }
}

// MARK: - Screen Tracking
extension BlueTriangle {
    @MainActor
    static func startScreenTrackingSetup() {
#if os(iOS)
         UIViewController.setUp()
#endif
    }
    
    @MainActor
    static func shutdownScreenTrackingSetup() {
#if os(iOS)
         UIViewController.removeSetUp()
#endif
    }

    @MainActor
    static func configureScreenTracking(with enabled: Bool) {
        store.makeLifecycleTracker()
#if os(iOS)
        BTTWebViewTracker.shouldCaptureRequests = store.getShouldNetworkCaptureRequests()
        BTTWebViewTracker.logger = logger
        if enabled {
             startScreenTrackingSetup()
        }
#endif
    }
}

// MARK: - Network State
extension BlueTriangle {
    static func configureMonitoringNetworkState(with enabled: Bool) {
        if enabled {
             store.makeNetworkStateMonitor()
        }
    }
}


// MARK: - LaunchTime
extension BlueTriangle {
    static func configureLaunchTime(with enabled: Bool) {
        if enabled{
            store.makeLaunchTimeMonitor()
        }
        AppNotificationLogger.removeObserver()
    }
}

//MARK: - Memory Warning
extension BlueTriangle {
    static func configureMemoryWarning(with enabled: Bool) {
        if enabled{
#if os(iOS)
            store.makeMemoryWarningWatchDog()
            store.getMemoryWarningWatchDog()?.start()
#endif
        }
    }
}

//MARK: - Session Expiry
extension BlueTriangle {
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
    static func configureSessionManager(forModeWithExpiry expiry: Millisecond) {
        
        if self.enableAllTracking{
            if let _ = store.getSessionManager() as? SessionManager {
                return
            }
            store.getSessionManager()?.stop()
            store.setSessionManager(store.enabledModeSessionManager)
            store.getSessionManager()?.start(with: expiry)
        }else{
            if let _ = store.getSessionManager() as? DisableModeSessionManager {
                return
            }
            store.getSessionManager()?.stop()
            store.setSessionManager(store.disableModeSessionManager)
            store.getSessionManager()?.start(with: expiry)
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
    
    internal static func updateSession(_ session : SessionData){
        store.updateSessionId(session.sessionID)
#if os(iOS)
        BTTWebViewTracker.updateSessionId(session.sessionID)
#endif
        SignalHandler.updateSessionID("\(session.sessionID)")
    }
    
    internal static func updateNetworkSampleRate(_ rate : Double) {
        configuration.networkSampleRate = rate
    }
    
    internal static func updateGroupedViewSampleRate(_ rate : Double) {
        configuration.groupedViewSampleRate = rate
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
        Task {
            configuration.enableScreenTracking = enabled
            await store.getLifecycleTracker()?.setLifecycleTracker(enabled)
#if os(iOS)
            if enabled {
                await startScreenTrackingSetup()
            } else {
                await shutdownScreenTrackingSetup()
            }
#endif
        }
    }
    
    internal static func updateCaptureRequests() {
        if let sessionData = sessionData(){
             store.setShouldNetworkCaptureRequests(sessionData.shouldNetworkCapture)
            let shouldCaptureRequests = store.getShouldNetworkCaptureRequests()
            if shouldCaptureRequests {
                if getNetworkRequestCapture() == nil {
                     setNetworkRequestCapture(store.makeCapturedRequestCollector())
                }
            } else {
                 setNetworkRequestCapture(store.makeCapturedRequestCollector())
            }
#if os(iOS)
            BTTWebViewTracker.shouldCaptureRequests = shouldCaptureRequests
#endif
        }
    }
    
    internal static func updateGroupedViewCaptureRequest() {
        if let sessionData = sessionData(){
            store.setShouldGroupedCaptureRequests(sessionData.shouldGroupedViewCapture)
            if  store.getShouldGroupedCaptureRequests() {
                if  getGroupRequestCapture() == nil {
                     setGroupRequestCapture(store.makeCapturedGroupRequestCollector())
                }
            } else {
                 setGroupRequestCapture(store.makeCapturedGroupRequestCollector())
            }
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
}

extension BlueTriangle {
    @objc
    public static func setGroupName(_ groupName: String) {
        guard isGroupingEnabled else { return }
        Task {
            await store.groupTimer.setGroupName(groupName)
        }
    }
    
    @objc
    public static func setNewGroup(_ newGroup: String) {
        guard isGroupingEnabled else { return }
        let time =  Date().timeIntervalSince1970
        Task {
            await store.groupTimer.setNewGroup(newGroup, time)
        }
    }
    
    public static func setGroupName(_ groupName: String) async {
        guard isGroupingEnabled else { return }
        await store.groupTimer.setGroupName(groupName)
    }
    
    public static func setNewGroup(_ newGroup: String) async {
        guard isGroupingEnabled else { return }
        let time =  Date().timeIntervalSince1970
        await store.groupTimer.setNewGroup(newGroup, time)
    }
    
    internal static func setLastGroupAction() {
        Task {
            await store.groupTimer.setLastAction(Date())
        }
    }
    
    internal static func addGroupTimer(_ timer: BTTimer) async {
        await store.groupTimer.add(timer: timer)
    }
    
    internal static func computeNameOfTheGroup() async {
        await store.groupTimer.refreshGroupName()
    }
    
    internal static func startGroupIfNeeded(_ time : TimeInterval) async {
        await store.groupTimer.startGroupIfNeeded(time)
    }
}


public extension BlueTriangle {
    
    static func makeTimer(_ pageName: String, brandValue: Decimal = 0.0, referringURL : String = "", url: String = "", timerType: BTTrackTimer.TimerType = .main) -> BTTrackTimer {
        let page = Page(pageName: pageName, brandValue: brandValue, referringURL: referringURL, url: url)
        let timer = BTTrackTimer(timer: timerFactory(page, timerType.btTimerType, false))
        return timer
    }

    static func startTimer(_ pageName: String, brandValue: Decimal = 0.0, referringURL : String = "", url: String = "", timerType: BTTrackTimer.TimerType = .main) async -> BTTrackTimer {
        let page = Page(pageName: pageName, brandValue: brandValue, referringURL: referringURL, url: url)
        let timer = await makeTimer(page: page, timerType: timerType)
        await timer.start()
        return timer
    }
    
    static func endTimer(_ timer: BTTrackTimer) async {
        await self.endTimer(timer, purchaseConfirmation: nil)
    }
    
    static func endTimer(_ timer: BTTrackTimer,
                              pageValue: Decimal = 0.0,
                              cartValue: Decimal,
                              cartCount: Int = 0,
                              cartCountCheckout: Int = 0,
                              orderNumber: String,
                              orderTime: TimeInterval = 0.0) async {
        let purchaseConfirmation: PurchaseConfirmation = .init(
            pageValue: pageValue,
            cartValue: cartValue,
            cartCount: cartCount,
            cartCountCheckout: cartCountCheckout,
            orderNumber: orderNumber,
            orderTime: orderTime)
        await self.endTimer(timer, purchaseConfirmation: purchaseConfirmation)
    }
    
    internal static func makeTimer(page: Page, timerType: BTTrackTimer.TimerType = .main)  async -> BTTrackTimer {
        let timer = BTTrackTimer(timer: timerFactory(page, timerType.btTimerType, false))
        return timer
    }
    
    internal static func endTimer(_ timer: BTTrackTimer, purchaseConfirmation: PurchaseConfirmation? = nil) async {
        await self.endTimer(timer.actorTimer, purchaseConfirmation: purchaseConfirmation)
    }
}
