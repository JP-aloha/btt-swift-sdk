//
//  NetworkMonitor.swift
//  
//  Created by Ashok Singh on 13/10/23
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Network
import Foundation
import Combine

enum NetworkState : String{
   case Wifi
   case Cellular
   case Ethernet
   case Other
   case Offline
}

protocol NetworkStateMonitorProtocol{
    var state : CurrentValueSubject<NetworkState?, Never> { get}
}


protocol NetworkPathMonitorProtocol{
    var pathUpdateHandler: ((_ newPath: NWPath) -> Void)? { get set}
    func start(queue: DispatchQueue)
    func cancel()
}

extension NWPathMonitor : NetworkPathMonitorProtocol{}

class NetworkStateMonitor : NetworkStateMonitorProtocol{
    var state: CurrentValueSubject<NetworkState?, Never> = .init(nil)
    private var monitor : NetworkPathMonitorProtocol
    private let logger : Logging
    
    init(_ logger : Logging, _ monitor : NetworkPathMonitorProtocol = NWPathMonitor()) {
        
        self.logger = logger
        self.monitor = monitor
        self.monitor.pathUpdateHandler = { [weak self] path  in
            if let self = self{
                let networkState = self.extractState(path: path)
                if networkState !=  state.value{
                    self.state.send(networkState)
                    self.logger.debug("Network state changed to \(networkState.rawValue.lowercased())")
                }
            }
        }
        
        self.monitor.start(queue: DispatchQueue.global(qos: .default))
        
        self.logger.debug("Network state monitoring started.")
    }
    
    private func extractState(path: NWPath) -> NetworkState{
        
        if path.status != .satisfied{
            return  .Offline
        }
        else if path.usesInterfaceType(.cellular) {
            return  .Cellular
        }
        else if path.usesInterfaceType(.wifi) {
            return  .Wifi
        }
        else if path.usesInterfaceType(.wiredEthernet) {
            return  .Ethernet
        }
        else{
            return  .Other
        }
    }

    deinit {
        monitor.cancel()
    }
}

