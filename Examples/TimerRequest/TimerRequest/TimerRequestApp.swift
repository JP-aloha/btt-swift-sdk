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
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            TestsHomeView(tests: ANRTestFactory().ANRTests())
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    AppDelegate().runTest(onEvent: .OnBecomingActive)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    AppDelegate().runTest(onEvent: .OnResumeFromBackground)
                }
        }
    }
}
