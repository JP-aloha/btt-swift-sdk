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

    private let notificationQueue = OperationQueue()
    private let configFetcher = BTTConfigurationFetcher(session: URLSession.config, cancellable: Set<AnyCancellable>())
    private let configRepo = BTTConfigurationRepo()
    private let configHandler = BTTRemoteConfigHandler()
    
    public func start(){
        
#if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: notificationQueue) { notification in
            self.onLaunch()
        }
#endif
    }
    
    private func onLaunch(){
        self.updateConfiguration()
    }
    
    private func updateConfiguration(){
        let updater = BTTConfigurationUpdater(configFetcher: configFetcher, configRepo: configRepo, configHandler: configHandler)
        updater.update {            
            print("Remote config updated")
        }
    }
    
}
