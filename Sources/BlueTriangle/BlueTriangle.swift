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

typealias SessionProvider = () -> Session

/// The entry point for interacting with the Blue Triangle SDK.
final public class BlueTriangle: NSObject {
    
    internal static var configuration = BlueTriangleConfiguration()

    internal static var screenTracker : BTTScreenLifecycleTracker?
    internal static var monitorNetwork: NetworkStateMonitorProtocol?
    private static var appEventObserver: AppEventObserver?
    private static var crashReportManager: CrashReportManaging?
    private static var launchTimeReporter : LaunchTimeReporter?
    private static var memoryWarningWatchDog : MemoryWarningWatchDog?
    private static var anrWatchDog : ANRWatchDog?
    private static var sessionManager : SessionManagerProtocol?
   
    internal static var enableAllTracking: Bool = {
        let value = configRepo.isEnableAllTracking()
        return  value
    }()
    
    private static let configRepo: BTTConfigurationRepo = {
        let config = BTTConfigurationRepo(BTTRemoteConfig.defaultConfig)
        return  config
    }()

    internal static let disableModeSessionManager : SessionManagerProtocol = {
        let configFetcher  =  BTTConfigurationFetcher()
        let configSyncer = BTTStoredConfigSyncer(configRepo: configRepo, logger: logger)
        let updater  =  BTTConfigurationUpdater(configFetcher: configFetcher, configRepo: configRepo, logger: logger, configAck: nil)
        return DisableModeSessionManager(logger, configRepo, updater, configSyncer)
    }()
    
    internal static let enabledModeSessionManager : SessionManagerProtocol = {
        let configFetcher  =  BTTConfigurationFetcher()
        let configSyncer = BTTStoredConfigSyncer(configRepo: configRepo, logger: logger)
        let configAck  =  RemoteConfigAckReporter(logger: logger, uploader: uploader)
        let updater  =  BTTConfigurationUpdater(configFetcher: configFetcher, configRepo: configRepo, logger: logger, configAck: configAck)
        return SessionManager(logger, configRepo, updater, configSyncer)
    }()
    
    private static let lock = NSLock()
    private static var activeTimers = [BTTimer]()
#if os(iOS)
    private static let matricKitWatchDog = MetricKitWatchDog()
#endif
    internal static func addActiveTimer(_ timer : BTTimer){
        activeTimers.append(timer)
#if os(iOS)
        matricKitWatchDog.saveCurrentTimerData(timer)
#endif
    }

    internal static func removeActiveTimer(_ timer : BTTimer){
        
        var index = 0
        var isTimerAvailable = false
        
        for timerObj in activeTimers{
            if timerObj == timer { isTimerAvailable = true
                break }
            index = index + 1
        }
        
        if isTimerAvailable {
            activeTimers.remove(at: index)
        }
    }
    
    internal static func recentTimer() -> BTTimer?{
        let timer = activeTimers.last
        return timer
    }
    
    internal static func updateSession(_ session : SessionData){
    
        _session.sessionID = session.sessionID
#if os(iOS)
        BTTWebViewTracker.updateSessionId(session.sessionID)
#endif
        SignalHandler.updateSessionID("\(session.sessionID)")
    }
    
    internal static func updateNetworkSampleRate(_ rate : Double){
        configuration.networkSampleRate = rate
    }
    
    internal static func updateIgnoreVcs(_ vcs : Set<String>?){
        if let vcs = vcs{
            configuration.ignoreViewControllers = vcs
        }
    }
    
    internal static func updateCaptureRequests() {
        shouldCaptureRequests = sessionData().shouldNetworkCapture
        
        if shouldCaptureRequests {
            if capturedRequestCollector == nil {
                capturedRequestCollector = makeCapturedRequestCollector()
            }
        } else {
            capturedRequestCollector = makeCapturedRequestCollector()
        }
        
#if os(iOS)
        BTTWebViewTracker.shouldCaptureRequests = shouldCaptureRequests
#endif
    }

    private static var _session: Session = {
        configuration.makeSession()
    }()
    
    internal static func session() -> Session {
        return _session
    }
    
    internal static func sessionData() -> SessionData {
        return sessionManager?.getSessionData() ?? SessionData(expiration: 0)
    }
    
    internal static func makeCapturedRequestCollector() -> CapturedRequestCollecting? {
        if shouldCaptureRequests {
            let collector = configuration.capturedRequestCollectorConfiguration.makeRequestCollector(
                logger: logger,
                networkCaptureConfiguration: .standard,
                requestBuilder: CapturedRequestBuilder.makeBuilder { session() },
                uploader: uploader)

            Task {
                await collector.configure()
            }
            return collector
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

    private static var timerFactory: (Page, BTTimer.TimerType) -> BTTimer = {
        configuration.timerConfiguration.makeTimerFactory(
            logger: logger,
            performanceMonitorFactory: configuration.makePerformanceMonitorFactory())
    }()

    private static var internalTimerFactory: () -> InternalTimer = {
        configuration.internalTimerConfiguration.makeTimerFactory(logger: logger)
    }()

    private static var shouldCaptureRequests: Bool = {
        sessionData().shouldNetworkCapture
    }()
    
    /// A Boolean value indicating  whether the SDK has been successfully configured and initialized.
    ///
    /// - `true`: The SDK has been configured and is ready to function. This means
    ///           that all necessary setup steps have been completed.
    /// - `false`: The SDK has not been configured. In this state, the SDK will not
    ///            function correctly, including the ability to fetch updates for the
    ///            enable/disable state via the Remote Configuration Updater.
    ///
    public private(set) static var initialized = false
    
    private static var capturedRequestCollector: CapturedRequestCollecting? = {
        return makeCapturedRequestCollector()
    }()


    //Cache components
    internal static var payloadCache : PayloadCacheProtocol = {
        PayloadCache.init(configuration.cacheMemoryLimit,
                          expiry: configuration.cacheExpiryDuration)
    }()
    
    /// Blue Triangle Technologies-assigned site ID.
    @objc public static var siteID: String {
        lock.sync { session().siteID }
    }

    /// Global User ID.
    @objc public static var globalUserID: Identifier {
        lock.sync { session().globalUserID }
    }

    /// Session ID.
    @objc public static var sessionID: Identifier {
        get {
            lock.sync { session().sessionID }
        }
    }

    /// Boolean value indicating whether user is a returning visitor.
    @objc public static var isReturningVisitor: Bool {
        get {
            lock.sync { session().isReturningVisitor }
        }
        set {
            lock.sync {_session.isReturningVisitor = newValue }
        }
    }

    /// A/B testing identifier.
    @objc public static var abTestID: String {
        get {
            lock.sync { session().abTestID }
        }
        set {
            lock.sync { _session.abTestID = newValue }
        }
    }

    /// Legacy campaign name.
    @available(*, deprecated, message: "Use `campaignName` instead.")
    @objc public static var campaign: String? {
        get {
            lock.sync { session().campaign }
        }
        set {
            lock.sync { _session.campaign = newValue}
        }
    }

    /// Campaign medium.
    @objc public static var campaignMedium: String {
        get {
            lock.sync { session().campaignMedium }
        }
        set {
            lock.sync { _session.campaignMedium = newValue}
        }
    }

    /// Campaign name.
    @objc public static var campaignName: String {
        get {
            lock.sync { session().campaignName }
        }
        set {
            lock.sync { _session.campaignName = newValue }
        }
    }

    /// Campaign source.
    @objc public static var campaignSource: String {
        get {
            lock.sync { session().campaignSource }
        }
        set {
            lock.sync { _session.campaignSource = newValue}
        }
    }

    /// Data center.
    @objc public static var dataCenter: String {
        get {
            lock.sync { session().dataCenter }
        }
        set {
            lock.sync { _session.dataCenter = newValue }
        }
    }

    /// Traffic segment.
    @objc public static var trafficSegmentName: String {
        get {
            lock.sync { session().trafficSegmentName }
        }
        set {
            lock.sync { _session.trafficSegmentName = newValue }
        }
    }

    /// Custom metrics.
     private static var metrics: [String: AnyCodable] {
        get {
            lock.sync { session().metrics ?? [:] }
        }
        set {
            lock.sync { self._session.metrics = (newValue.isEmpty ? nil : newValue)}
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
            self.applyAllTrackerState()
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
        
        self.configureSessionManager(forModeWithExpiry: configuration.sessionExpiryDuration)
        
        if self.enableAllTracking {
            self.startAllTrackers()
        }else{
            self.stopAllTrackers()
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
                       
        self.updateCaptureRequests()
        
        if launchTimeReporter == nil{
            configureLaunchTime(with: configuration.enableLaunchTime)
        }
        
        if let crashConfig = configuration.crashTracking.configuration {
            DispatchQueue.global(qos: .utility).async {
                if crashReportManager == nil{
                    configureCrashTracking(with: crashConfig)
                }
                
                if btcrashReport == nil{
                    configureSignalCrash(with: crashConfig, debugLog: configuration.enableDebugLogging)
                }
            }
        }
      
        if memoryWarningWatchDog == nil{
            configureMemoryWarning(with: configuration.enableMemoryWarning)
        }
        
        if anrWatchDog == nil{
            configureANRTracking(with: configuration.ANRMonitoring, enableStackTrace: configuration.ANRStackTrace,
                                 interval: configuration.ANRWarningTimeInterval)
        }

        if screenTracker == nil{
            configureScreenTracking(with: configuration.enableScreenTracking)
        }
        
        if monitorNetwork == nil{
            configureMonitoringNetworkState(with: configuration.enableTrackingNetworkState)
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
        
        //network capture
        capturedRequestCollector = nil
        
        //Stop Launch Time
        launchTimeReporter?.stop()
        launchTimeReporter = nil
        
        //Stop Crash Reporting
        crashReportManager?.stop()
        crashReportManager = nil
        btcrashReport?.stop()
        btcrashReport = nil
        
        //Stop Memory Warning
        memoryWarningWatchDog?.stop()
        memoryWarningWatchDog = nil
        
        //StopANR
        anrWatchDog?.stop()
        anrWatchDog = nil
        
        //Stop Screen Tracking
#if os(iOS)
        UIViewController.removeSetUp()
        screenTracker?.stop()
        screenTracker = nil
#endif

        //Stop Network Status
        monitorNetwork?.stop()
        monitorNetwork = nil
    }

    // We want to allow multiple configurations for testing
    internal static func reconfigure(
        configuration: BlueTriangleConfiguration = .init(),
        session: Session? = nil,
        logger: Logging? = nil,
        uploader: Uploading? = nil,
        timerFactory: ((Page, BTTimer.TimerType) -> BTTimer)? = nil,
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
            self.capturedRequestCollector = requestCollector
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
    static func makeTimer(page: Page, timerType: BTTimer.TimerType = .main) -> BTTimer {
        lock.lock()
       // precondition(initialized, "BlueTriangle must be initialized before sending timers.")
        let timer = timerFactory(page, timerType)
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
    static func startTimer(page: Page, timerType: BTTimer.TimerType = .main) -> BTTimer {
        let timer = makeTimer(page: page, timerType: timerType)
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
        
        if let _ = BlueTriangle.screenTracker {
            purchaseConfirmation?.orderTime = timer.endTime
            let request: Request
            lock.lock()
            do {
                request = try configuration.requestBuilder.builder(session(), timer, purchaseConfirmation)
                lock.unlock()
            } catch {
                lock.unlock()
                logger.error(error.localizedDescription)
                return
            }
            uploader.send(request: request)
        }
    }
}

// MARK: - Custom Metrics
public extension BlueTriangle {
    
    private static func _setCustomVariable(_ value: Any?, _ key: String) {
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
        self.metrics.removeValue(forKey: name)
    }
    
    /// Clears all custom variables from the dictionary.
    ///
    /// This function resets the  dictionary to an empty state, removing all previously set custom variables.
    ///
    @objc
    static func clearAllCustomVariables() {
        self.metrics = [:]
    }
}

// MARK: - Network Capture
public extension BlueTriangle {
    internal static func timerDidStart(_ type: BTTimer.TimerType, page: Page, startTime: TimeInterval) {
        guard case .main = type else {
            return
        }

        Task {
            await capturedRequestCollector?.start(page: page, startTime: startTime)
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

    /// Captures a network request.
    /// - Parameters:
    ///   - timer: The request timer.
    ///   - data: The request response data.
    ///   - response: The request response.
    ///   - error: The response error
    
    static func captureRequest(timer: InternalTimer, response: URLResponse?) {
        Task {
            await capturedRequestCollector?.collect(timer: timer, response: response)
        }
    }
    
    internal static func captureRequest(timer: InternalTimer, response: CustomResponse) {
        Task {
            await capturedRequestCollector?.collect(timer: timer, response: response)
        }
    }

    /// Captures a network request.
    /// - Parameters:
    ///   - timer: The request timer.
    ///   - tuple: The asynchronously-delivered tuple containing the request contents as a Data instance and a URLResponse.
    static func captureRequest(timer: InternalTimer, tuple: (Data, URLResponse)) {
        Task {
            await capturedRequestCollector?.collect(timer: timer, response: tuple.1)
        }
    }
    
    static func captureRequest(timer: InternalTimer, request : URLRequest, error: Error?) {
        Task {
            await capturedRequestCollector?.collect(timer: timer, request: request, error: error)
        }
    }

    /// Captures a network request.
    /// - Parameter metrics: An object encapsulating the metrics for a session task.
    static func captureRequest(metrics: URLSessionTaskMetrics, error : Error?) {
        Task {
            await capturedRequestCollector?.collect(metrics: metrics, error: error)
        }
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
        crashReportManager?.uploadError(error, file: file, function: function, line: line)
    }
}

private var btcrashReport: BTSignalCrashReporter?

// MARK: - Crash Reporting
extension BlueTriangle {
    static func configureCrashTracking(with crashConfiguration: CrashReportConfiguration) {
        crashReportManager = CrashReportManager(crashReportPersistence: CrashReportPersistence.self,
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
        btcrashReport = BTSignalCrashReporter(directory: SignalHandler.reportsFolderPath(), logger: logger,
                                              uploader: uploader,
                                              session: {session()})
        btcrashReport?.configureSignalCrashHandling(configuration: crashConfiguration)
    }

    /// Saves an exception to upload to the Blue Triangle portal on next launch.
    ///
    /// Use this method to store exceptions caught by other exception handlers.
    ///
    /// - Parameter exception: The exception to upload.
    public static func storeException(exception: NSException) {
        let pageName = BlueTriangle.recentTimer()?.page.pageName
        let crashReport = CrashReport(sessionID: sessionID, exception: exception, pageName: pageName)
        CrashReportPersistence.save(crashReport)
    }
}

//MARK: - ANR Tracking
extension BlueTriangle{
    static func configureANRTracking(with enabled: Bool, enableStackTrace : Bool, interval: TimeInterval){
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
            monitorNetwork = NetworkStateMonitor.init(logger)
        }
    }
}


// MARK: - LaunchTime
extension BlueTriangle{
    

    static func configureLaunchTime(with enabled: Bool){
        if enabled {
            let launchMonitor = LaunchTimeMonitor(logger: logger)
            launchTimeReporter = LaunchTimeReporter(using: {session()},
                                                    uploader: configuration.uploaderConfiguration.makeUploader(logger: logger, failureHandler: RequestFailureHandler(
                                                        file: .requests,
                                                        logger: logger)),
                                                    logger: BlueTriangle.logger,
                                                    monitor: launchMonitor)
            
        }
        
        AppNotificationLogger.removeObserver()
    }
}

//MARK: - Memory Warning
extension BlueTriangle{
    static func configureMemoryWarning(with enabled: Bool){
        if enabled {
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
#if os(iOS)
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
#endif
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
