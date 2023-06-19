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
            config.siteID = "bluetrianglesdk3280971z"
            config.abTestID = "MY_AB_TEST_ID"
            config.campaignMedium = "MY_CAMPAIGN_MEDIUM"
            config.campaignName = "MY_CAMPAIGN_NAME"
            config.campaignSource = "MY_CAMPAIGN_SOURCE"
            config.dataCenter = "MY_DATA_CENTER"
            config.trafficSegmentName = "MY_TRAFFIC_SEGMENT"
            config.networkSampleRate = 1.0
            config.crashTracking = .nsException
            config.enableScreenTracking = true
            config.enableDebugLogging = true
            config.ANRMonitoring = true
        }

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
}
