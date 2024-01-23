//
//  NetworkRecorder.swift
//  
//  Created by Ashok Singh on 16/10/23
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit
import Combine

protocol BTTimerNetStateAccumulatorProtocol{
    func start()
    func stop()
    func makeReport() -> NetworkReport
}

class BTTimerNetStateAccumulator  : BTTimerNetStateAccumulatorProtocol{
    
    let offline = NetworkStateStopWatch(type: .Offline)
    let wifi = NetworkStateStopWatch(type: .Wifi)
    let cellular = NetworkStateStopWatch(type: .Cellular)
    let ethernet = NetworkStateStopWatch(type: .Ethernet)
    let other = NetworkStateStopWatch(type: .Other)
    
    private var currentNetwork : NetworkState?
    private var cancellable : AnyCancellable?
    private var monitor : NetworkStateMonitorProtocol
    
    init(_ monitor: NetworkStateMonitorProtocol) {
        self.monitor = monitor
    }
    
    func start(){
        self.cancellable = monitor.state
            .receive(on: RunLoop.main)
            .sink { _ in
            }receiveValue: { value in
                self.updateStopWatch(value)
            }
    }
    
    func stop(){
        self.updateStopWatch(monitor.state.value)
        self.cancellable = nil
    }
    
    func makeReport() -> NetworkReport{
        
        self.stop()
        
        return NetworkReport(offline: offline.duration,
                             wifi: wifi.duration,
                             cellular: cellular.duration,
                             ethernet: ethernet.duration,
                             other: other.duration)
    }
    
    private func updateStopWatch(_ type : NetworkState?){
        
        // Save previous network type data
        if let previousType = currentNetwork{
            
            switch previousType {
            case .Wifi:
                wifi.stop()
            case .Cellular:
                cellular.stop()
            case .Ethernet:
                ethernet.stop()
            case .Other:
                other.stop()
            case .Offline:
                offline.stop()
            }
        }
        
        // Start current network type data
        if let currentType = type{
           
            self.currentNetwork = type
            
            // Save previous network data
            switch currentType {
            case .Wifi:
                wifi.start()
            case .Cellular:
                cellular.start()
            case .Ethernet:
                ethernet.start()
            case .Other:
                other.start()
            case .Offline:
                offline.start()
            }
        }
    }
}

class NetworkStateStopWatch {
   
    let type : NetworkState
    private var startTime : Millisecond = 0
    private(set) var duration : Millisecond = 0
    
    init(type: NetworkState) {
        self.type = type
    }
    
    func stop(){
        duration = duration + (Date().timeIntervalSince1970.milliseconds - startTime)
    }
    
    func start(){
        startTime = Date().timeIntervalSince1970.milliseconds
    }
}


struct NetworkReport: Codable, Equatable {
    let offline: Millisecond
    let wifi: Millisecond
    let cellular: Millisecond
    let ethernet: Millisecond
    let other: Millisecond
}

