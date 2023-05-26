//
//  TimerRequestApp.swift
//  TimerRequest
//
//  Created by Mathew Gacy on 7/31/22.
//

import BlueTriangle
import SwiftUI

@main
struct TimerRequestApp: App {
    init() {
        BlueTriangle.configure { config in
            config.siteID = Constants.siteID
            config.enableDebugLogging = true
            config.performanceMonitorSampleRate = 1
            config.crashTracking  = .nsException
            config.ANRMonitoring = true
            config.ANRWarningTimeInterval = 1
        }
    }

    var body: some Scene {
        WindowGroup {
            TestsHomeView(tests: ANRTestFactory().ANRTests())
        }
    }
}
