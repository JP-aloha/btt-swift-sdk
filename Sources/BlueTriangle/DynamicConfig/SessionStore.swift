//
//  SessionStore.swift
//
//
//  Created by Ashok Singh on 07/11/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

class SessionStore {
    
    private let sessionKey = "SAVED_SESSION_DATA"
    
    func saveSession(_ session: SessionData) {
        if let encoded = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encoded, forKey: sessionKey)
        }
    }
    
    func retrieveSessionData() -> SessionData? {
        if let savedSession = UserDefaults.standard.object(forKey: sessionKey) as? Data {
            if let decodedSession = try? JSONDecoder().decode(SessionData.self, from: savedSession) {
                return decodedSession
            }
        }
        
        return nil
    }
    
    func isExpired() -> Bool{
        
        var isExpired : Bool = true
        
        if let session = retrieveSessionData(){
            let currentTime = Int64(Date().timeIntervalSince1970) * 1000
            if  currentTime > session.expiration{
                isExpired = true
            }else{
                isExpired = false
            }
        }else{
            isExpired = true
        }
        
        return isExpired
    }
    
    
    func removeSessionData() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        UserDefaults.standard.synchronize()
    }
}

final class SessionData: Codable, @unchecked Sendable {
    
    private let lock = NSLock()
    private var _expiration: Millisecond
    private var _isNewSession: Bool
    private var _shouldNetworkCapture: Bool
    private var _shouldGroupedViewCapture: Bool
    private var _enableScreenTracking: Bool
    private var _networkSampleRate: Double
    private var _groupedViewSampleRate: Double
    private var _enableGrouping: Bool
    private var _groupingIdleTime: Double
    private var _ignoreViewControllers: Set<String>
    private var _enableCrashTracking: Bool
    private var _enableANRTracking: Bool
    private var _enableMemoryWarning: Bool
    private var _enableLaunchTime: Bool
    private var _enableWebViewStitching: Bool
    private var _enableNetworkStateTracking: Bool
    private var _enableGroupingTapDetection: Bool
    let sessionID: Identifier
    
    init(expiration: Millisecond) {
        self.sessionID = SessionData.generateSessionID()
        self._expiration = expiration
        self._isNewSession = true
        self._shouldNetworkCapture = false
        self._shouldGroupedViewCapture = false
        let config = BlueTriangle.configuration
        self._enableScreenTracking = config.enableScreenTracking
        self._networkSampleRate = config.networkSampleRate
        self._groupedViewSampleRate = config.groupedViewSampleRate
        self._enableGrouping = config.enableGrouping
        self._groupingIdleTime = config.groupingIdleTime
        self._ignoreViewControllers = config.ignoreViewControllers
        self._enableCrashTracking = config.crashTracking == .nsException
        self._enableANRTracking = config.ANRMonitoring
        self._enableMemoryWarning = config.enableMemoryWarning
        self._enableLaunchTime = config.enableLaunchTime
        self._enableWebViewStitching = config.enableWebViewStitching
        self._enableNetworkStateTracking = config.enableTrackingNetworkState
        self._enableGroupingTapDetection = config.enableGroupingTapDetection
    }
    
    private static func generateSessionID() -> Identifier {
        return Identifier.random()
    }
    
    // MARK: Computed (Thread-Safe)
    var expiration: Millisecond {
        get { lock.sync { _expiration } }
        set { lock.sync { _expiration = newValue } }
    }
    
    var isNewSession: Bool {
        get { lock.sync { _isNewSession } }
        set { lock.sync { _isNewSession = newValue } }
    }
    
    var shouldNetworkCapture: Bool {
        get { lock.sync { _shouldNetworkCapture } }
        set { lock.sync { _shouldNetworkCapture = newValue } }
    }
    
    var shouldGroupedViewCapture: Bool {
        get { lock.sync { _shouldGroupedViewCapture } }
        set { lock.sync { _shouldGroupedViewCapture = newValue } }
    }
    
    var enableScreenTracking: Bool {
        get { lock.sync { _enableScreenTracking } }
        set { lock.sync { _enableScreenTracking = newValue } }
    }
    
    var networkSampleRate: Double {
        get { lock.sync { _networkSampleRate } }
        set { lock.sync { _networkSampleRate = newValue } }
    }
    
    var groupedViewSampleRate: Double {
        get { lock.sync { _groupedViewSampleRate } }
        set { lock.sync { _groupedViewSampleRate = newValue } }
    }
    
    var enableGrouping: Bool {
        get { lock.sync { _enableGrouping } }
        set { lock.sync { _enableGrouping = newValue } }
    }
    
    var groupingIdleTime: Double {
        get { lock.sync { _groupingIdleTime } }
        set { lock.sync { _groupingIdleTime = newValue } }
    }
    
    var ignoreViewControllers: Set<String> {
        get { lock.sync { _ignoreViewControllers } }
        set { lock.sync { _ignoreViewControllers = newValue } }
    }
    
    // NEW FLAGS
    var enableCrashTracking: Bool {
        get { lock.sync { _enableCrashTracking } }
        set { lock.sync { _enableCrashTracking = newValue } }
    }
    
    var enableANRTracking: Bool {
        get { lock.sync { _enableANRTracking } }
        set { lock.sync { _enableANRTracking = newValue } }
    }
    
    var enableMemoryWarning: Bool {
        get { lock.sync { _enableMemoryWarning } }
        set { lock.sync { _enableMemoryWarning = newValue } }
    }
    
    var enableLaunchTime: Bool {
        get { lock.sync { _enableLaunchTime } }
        set { lock.sync { _enableLaunchTime = newValue } }
    }
    
    var enableWebViewStitching: Bool {
        get { lock.sync { _enableWebViewStitching } }
        set { lock.sync { _enableWebViewStitching = newValue } }
    }
    
    var enableNetworkStateTracking: Bool {
        get { lock.sync { _enableNetworkStateTracking } }
        set { lock.sync { _enableNetworkStateTracking = newValue } }
    }
    
    var enableGroupingTapDetection: Bool {
        get { lock.sync { _enableGroupingTapDetection } }
        set { lock.sync { _enableGroupingTapDetection = newValue } }
    }
    
    // MARK: Codable
    enum CodingKeys: String, CodingKey {
        case sessionID, expiration, isNewSession, shouldNetworkCapture,
             shouldGroupedViewCapture, enableScreenTracking,
             networkSampleRate, groupedViewSampleRate,
             enableGrouping, groupingIdleTime, ignoreViewControllers,
             enableCrashTracking, enableANRTracking, enableMemoryWarning,
             enableLaunchTime, enableWebViewStitching,
             enableNetworkStateTracking, enableGroupingTapDetection
    }
    
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.sessionID = try c.decode(Identifier.self, forKey: .sessionID)
        self._expiration = try c.decode(Millisecond.self, forKey: .expiration)
        self._isNewSession = try c.decode(Bool.self, forKey: .isNewSession)
        self._shouldNetworkCapture = try c.decode(Bool.self, forKey: .shouldNetworkCapture)
        self._shouldGroupedViewCapture = try c.decode(Bool.self, forKey: .shouldGroupedViewCapture)
        self._enableScreenTracking = try c.decode(Bool.self, forKey: .enableScreenTracking)
        self._networkSampleRate = try c.decode(Double.self, forKey: .networkSampleRate)
        self._groupedViewSampleRate = try c.decode(Double.self, forKey: .groupedViewSampleRate)
        self._enableGrouping = try c.decode(Bool.self, forKey: .enableGrouping)
        self._groupingIdleTime = try c.decode(Double.self, forKey: .groupingIdleTime)
        self._ignoreViewControllers = try c.decode(Set<String>.self, forKey: .ignoreViewControllers)
        self._enableCrashTracking = try c.decode(Bool.self, forKey: .enableCrashTracking)
        self._enableANRTracking = try c.decode(Bool.self, forKey: .enableANRTracking)
        self._enableMemoryWarning = try c.decode(Bool.self, forKey: .enableMemoryWarning)
        self._enableLaunchTime = try c.decode(Bool.self, forKey: .enableLaunchTime)
        self._enableWebViewStitching = try c.decode(Bool.self, forKey: .enableWebViewStitching)
        self._enableNetworkStateTracking = try c.decode(Bool.self, forKey: .enableNetworkStateTracking)
        self._enableGroupingTapDetection = try c.decode(Bool.self, forKey: .enableGroupingTapDetection)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(sessionID, forKey: .sessionID)
        try c.encode(expiration, forKey: .expiration)
        try c.encode(isNewSession, forKey: .isNewSession)
        try c.encode(shouldNetworkCapture, forKey: .shouldNetworkCapture)
        try c.encode(shouldGroupedViewCapture, forKey: .shouldGroupedViewCapture)
        try c.encode(enableScreenTracking, forKey: .enableScreenTracking)
        try c.encode(networkSampleRate, forKey: .networkSampleRate)
        try c.encode(groupedViewSampleRate, forKey: .groupedViewSampleRate)
        try c.encode(enableGrouping, forKey: .enableGrouping)
        try c.encode(groupingIdleTime, forKey: .groupingIdleTime)
        try c.encode(ignoreViewControllers, forKey: .ignoreViewControllers)
        
        try c.encode(enableCrashTracking, forKey: .enableCrashTracking)
        try c.encode(enableANRTracking, forKey: .enableANRTracking)
        try c.encode(enableMemoryWarning, forKey: .enableMemoryWarning)
        try c.encode(enableLaunchTime, forKey: .enableLaunchTime)
        try c.encode(enableWebViewStitching, forKey: .enableWebViewStitching)
        try c.encode(enableNetworkStateTracking, forKey: .enableNetworkStateTracking)
        try c.encode(enableGroupingTapDetection, forKey: .enableGroupingTapDetection)
    }
}
