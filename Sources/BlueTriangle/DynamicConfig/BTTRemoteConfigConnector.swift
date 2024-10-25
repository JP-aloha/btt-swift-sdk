//
//  BTTRemoteConfigConnector.swift
//  
//
//  Created by Ashok Singh on 06/09/24.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif
import Combine

class BTTRemoteConfigConnector {

    private let configFetcher = BTTConfigurationFetcher(session: URLSession.config, cancellable: Set<AnyCancellable>())
    private let configRepo = BTTConfigurationRepo()
    private let configHandler = BTTRemoteConfigHandler()
    private let queue = DispatchQueue(label: "com.bluetriangle.connector", qos: .userInitiated, autoreleaseFrequency: .workItem)
    lazy var updater = BTTConfigurationUpdater(configFetcher: configFetcher, configRepo: configRepo)
    
    public func start(){
#if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { notification in
            self.onAppLaunch()
        }
#endif
    }
    
    func onAppLaunch(){
        queue.async {
            let isNewSession = BlueTriangle.sessionManager.getSessionData().isNewSession
            self.updater.update(isNewSession) { remoteConfig in
                if let config = remoteConfig{
                    self.configHandler.updateRemoteConfig(config)
                }
            }
        }
    }
}
