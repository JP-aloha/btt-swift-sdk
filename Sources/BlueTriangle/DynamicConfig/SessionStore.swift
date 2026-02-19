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


class SessionData: Codable {
    let sessionID: Identifier
    var expiration: Millisecond
    var isNewSession: Bool
    var shouldNetworkCapture: Bool
    var enableScreenTracking: Bool
    var networkSampleRate : Double
    var enableGrouping: Bool
    var groupingIdleTime: Double
    var ignoreViewControllers: Set<String>
    
    var enableCrashTracking: Bool
    var enableANRTracking: Bool
    var enableMemoryWarning: Bool
    var enableLaunchTime: Bool
    var enableWebViewStitching: Bool
    var enableNetworkStateTracking: Bool
    var enableGroupingTapDetection: Bool
    
    var checkoutTrackingEnabled : Bool
    var checkoutClassName : [String]
    var checkoutURL : String
    var checkoutAmount : Double
    var checkoutCartCount : Int
    var checkoutCartCountCheckout: Int
    var checkoutOrderNumber : String
    var checkoutTimeValue : Int
    
    init(expiration: Millisecond) {
        self.expiration = expiration
        self.sessionID =  SessionData.generateSessionID()
        self.isNewSession = true
        self.shouldNetworkCapture = false
        self.enableGrouping = BlueTriangle.configuration.enableGrouping
        self.groupingIdleTime = BlueTriangle.configuration.groupingIdleTime
        self.enableScreenTracking = BlueTriangle.configuration.enableScreenTracking
        self.networkSampleRate = BlueTriangle.configuration.networkSampleRate
        self.ignoreViewControllers = BlueTriangle.configuration.ignoreViewControllers
        
        self.enableCrashTracking = BlueTriangle.configuration.crashTracking == .nsException
        self.enableANRTracking = BlueTriangle.configuration.ANRMonitoring
        self.enableMemoryWarning = BlueTriangle.configuration.enableMemoryWarning
        self.enableLaunchTime = BlueTriangle.configuration.enableLaunchTime
        self.enableWebViewStitching =  BlueTriangle.configuration.enableWebViewStitching
        self.enableNetworkStateTracking = BlueTriangle.configuration.enableTrackingNetworkState
        self.enableGroupingTapDetection =  BlueTriangle.configuration.enableGroupingTapDetection
        
        self.checkoutTrackingEnabled = BlueTriangle.configuration.checkoutTrackingEnabled
        self.checkoutClassName = BlueTriangle.configuration.checkoutClassName
        self.checkoutURL = BlueTriangle.configuration.checkoutURL
        self.checkoutAmount = BlueTriangle.configuration.checkoutAmount
        self.checkoutCartCount = BlueTriangle.configuration.checkoutCartCount
        self.checkoutCartCountCheckout = BlueTriangle.configuration.checkoutCartCountCheckout
        self.checkoutOrderNumber = BlueTriangle.configuration.checkoutOrderNumber
        self.checkoutTimeValue = BlueTriangle.configuration.checkoutTimeValue
    }
    
    private static func generateSessionID()-> Identifier {
        let sessionID = Identifier.random()
        return sessionID
    }
}
