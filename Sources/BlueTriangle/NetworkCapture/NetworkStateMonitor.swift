//
//  NetworkMonitor.swift
//  
//
//  Created by Ashok Singh on 13/10/23.
//

import Network
import Foundation
import Combine

enum NetworkState : CustomStringConvertible {
   case Wifi
   case Cellular
   case Ethernet
   case Other
   case Offline
   
   public var description: String {
       switch self {
       case .Wifi:
           return "wifi"
       case .Cellular:
           return "cellular"
       case .Ethernet:
           return "ethernet"
       case .Other:
           return "other"
       case .Offline:
           return "offline"
       }
   }
}

protocol NetworkStateMonitorProtocol{
    var state : CurrentValueSubject<NetworkState, Error> { get set }
}

class NetworkStateMonitor : NetworkStateMonitorProtocol{
    var state: CurrentValueSubject<NetworkState, Error> = .init(.Offline)
    private var network : NetworkState = .Offline
    private let monitor : NWPathMonitor
    private let logger : Logging
    
    init(_ logger : Logging) {
        
        self.logger = logger
        self.state.send(.Offline)
       
        self.monitor = NWPathMonitor.init()
        self.monitor.pathUpdateHandler = { path in
            self.setUpConnection(path: path)
        }
        
        self.monitor.start(queue: DispatchQueue.global(qos: .default))
        
        self.logger.debug("Network state monitoring started.")
    }
    
    private func setUpConnection(path: NWPath) {
        
        var newNetwork : NetworkState = .Offline

        guard path.status == .satisfied else {
            newNetwork = .Offline
            
            if self.network != newNetwork{
                self.network = newNetwork
                self.state.send(newNetwork)
                self.logger.debug("Network state changed to \(network.description)")
            }
                        
            return
        }
        
        if path.usesInterfaceType(.cellular) {
            newNetwork = .Cellular
        } else if path.usesInterfaceType(.wifi) {
            newNetwork = .Wifi
        } else if path.usesInterfaceType(.wiredEthernet) {
            newNetwork = .Ethernet
        }else{
            newNetwork = .Other
        }
        
        if self.network != newNetwork{
            self.network = newNetwork
            self.state.send(newNetwork)
            self.logger.debug("Network state changed to \(network.description)")
        }
    }

    deinit {
        monitor.cancel()
    }
}

