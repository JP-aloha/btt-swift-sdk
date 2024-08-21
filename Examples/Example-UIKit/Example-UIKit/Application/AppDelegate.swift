//
//  AppDelegate.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 10/15/21.
//

import UIKit
import BlueTriangle

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // ...
        
        // Configure BlueTriangle
        BlueTriangle.configure { config in
            
            config.siteID = Constants.siteID
            config.enableDebugLogging = true
            config.performanceMonitorSampleRate = 1
            config.networkSampleRate = 1
            config.crashTracking  = .nsException
            config.ANRMonitoring = true
            config.ANRWarningTimeInterval = 1
            config.enableScreenTracking = true
            config.enableTrackingNetworkState = true
            config.enableMemoryWarning = true
            config.networkSampleRate = 1
            config.isPerformanceMonitorEnabled = true
            config.cacheMemoryLimit = 5 * 1024
            config.cacheExpiryDuration = 2 * 60 * 1000
        } 
        
        runTest(onEvent: .OnAppLaunch)
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        runTest(onEvent: .OnBecomingActive)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        runTest(onEvent: .OnResumeFromBackground)
    }
    
}

extension AppDelegate {
    func runTest(onEvent: TestScheduler.Event) {
        TestScheduler.getSchedule(event: onEvent).forEach{ $0.run() }
        
    }
}
