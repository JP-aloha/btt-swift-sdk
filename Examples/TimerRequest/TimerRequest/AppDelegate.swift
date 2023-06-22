//
//  AppDelegate.swift
//  TimerRequest
//
//  Created by admin on 09/06/23.
//

import Foundation
import UIKit
import BlueTriangle

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        configure {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.runTest(onEvent: .OnAppLaunch)
            }
        }
        
        
        return true
    }
    
    func configure(completion: ()-> Void ) {
        BlueTriangle.configure { config in
            config.siteID = Constants.siteID
            config.enableDebugLogging = true
            config.performanceMonitorSampleRate = 1
            config.crashTracking  = .nsException
            config.ANRMonitoring = true
            config.ANRWarningTimeInterval = 1
            config.enableScreenTracking = true
            
            completion()
        }
    }
}

extension AppDelegate {
    func runTest(onEvent: TestScheduler.Event) {
        TestScheduler.getSchedule(event: onEvent).forEach{ $0.run() }
        
    }
}
