//
//  NetworkMonitor.swift
//  
//  Created by Ashok Singh on 13/10/23
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Network
import Foundation
import Combine

indirect enum NetworkState : CustomStringConvertible, Equatable{
    case Wifi
    case Cellular(NetworkType)
    case Ethernet
    case Other
    case Offline
    
    var description: String {
        switch self {
        case .Wifi:
            return "WiFi"
        case .Cellular(let type):
            return type.description
        case .Ethernet:
            return "Ethernet"
        case .Other:
            return "Other"
        case .Offline:
            return "Offline"
        }
    }
}

protocol NetworkStateMonitorProtocol{
    var state : CurrentValueSubject<NetworkState?, Never> { get}
    var networkSource : CurrentValueSubject<String?, Never> { get}
}

protocol NetworkPathMonitorProtocol{
    var pathUpdateHandler: (@Sendable (_ newPath: NWPath) -> Void)? { get set}
    func start(queue: DispatchQueue)
    func cancel()
}

extension NWPathMonitor : NetworkPathMonitorProtocol{}

class NetworkStateMonitor : NetworkStateMonitorProtocol{
    var state: CurrentValueSubject<NetworkState?, Never> = .init(nil)
    var networkSource: CurrentValueSubject<String?, Never> = .init(nil)
    private var monitor : NetworkPathMonitorProtocol
    private let logger : Logging
    private let telephony : NetworkTelephonyProtocol
    private var lastPath: NWPath?
    
    init(_ logger : Logging, _ monitor : NetworkPathMonitorProtocol = NWPathMonitor(),_ telephony : NetworkTelephonyProtocol = NetworkTelephonyHandler()) {
        
        self.logger = logger
        self.monitor = monitor
        self.telephony = telephony
        self.monitor.pathUpdateHandler = { [weak self] path  in
            if let self = self{
                self.lastPath = path
                let networkState = self.extractState(path: path)
                if networkState !=  self.state.value{
                    self.updateNetworkState(networkState, path: path)
                    self.logger.debug("Network state changed to \(networkState.description.lowercased())")
                }
            }
        }
        
        self.observeNetworkType()
        self.monitor.start(queue: DispatchQueue.global(qos: .default))
        
        self.logger.debug("Network state monitoring started.")
    }
    
    private func updateNetworkState(_ state : NetworkState, path: NWPath){
        if path.usesInterfaceType(.cellular){
            let technology = telephony.getNetworkTechnology()
            self.networkSource.send(technology)
        }else{
            self.networkSource.send(nil)
        }
        
        self.state.send(state)
    }
    
    private func extractState(path: NWPath) -> NetworkState{
        
        if path.status != .satisfied{
            return  .Offline
        }
        else if path.usesInterfaceType(.cellular) {
            let networkType = telephony.getNetworkType()
            return  .Cellular(networkType)
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
    
    private func observeNetworkType(){
        self.telephony.observeNetworkType { source in
            if let path = self.lastPath{
                let networkState = self.extractState(path: path)
                if networkState !=  self.state.value{
                    self.updateNetworkState(networkState, path: path)
                }
            }
        }
    }
    
    deinit {
        monitor.cancel()
    }
}

