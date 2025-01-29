//
//  NetworkRecorder.swift
//
//  Created by Ashok Singh on 16/10/23
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

protocol BTTimerNetStateAccumulatorProtocol{
    func start()
    func stop()
    func makeReport() -> NetworkReport
}

class BTTimerNetStateAccumulator  : BTTimerNetStateAccumulatorProtocol {
    
    let offline = NetworkStateStopWatch(type: .Offline)
    let wifi = NetworkStateStopWatch(type: .Wifi)
    let ethernet = NetworkStateStopWatch(type: .Ethernet)
    let other = NetworkStateStopWatch(type: .Other)
    
    //celluler
    let cellular5g = NetworkStateStopWatch(type: .Cellular(NetworkType._5G))
    let cellular4g = NetworkStateStopWatch(type: .Cellular(NetworkType._4G))
    let cellular3g = NetworkStateStopWatch(type: .Cellular(NetworkType._3G))
    let cellular2g = NetworkStateStopWatch(type: .Cellular(NetworkType._2G))
    let cellularUnknown = NetworkStateStopWatch(type: .Cellular(NetworkType._Unknown))
    
    private var networkSource = Set<String>()
    private var currentNetwork : NetworkState?
    private var cancellable : AnyCancellable?
    private var sourceCancellable : AnyCancellable?
    private var monitor : NetworkStateMonitorProtocol
    
    init(_ monitor: NetworkStateMonitorProtocol) {
        self.monitor = monitor
    }
    
    func start(){
        self.cancellable = monitor.state
            .receive(on: RunLoop.main)
            .sink { _ in
            }receiveValue: { [weak self] value in
                self?.updateStopWatch(value)
            }
        
        self.sourceCancellable = monitor.networkSource
            .receive(on: RunLoop.main)
            .sink { _ in
            }receiveValue: { [weak self] value in
                if let source = value{
                    self?.networkSource.insert(source)
                }
            }
    }
    
    func stop(){
        self.updateStopWatch(monitor.state.value)
        self.cancellable = nil
        self.sourceCancellable = nil
    }
    
    func makeReport() -> NetworkReport{
        
        self.stop()
        
        let netSource = networkSource.joined(separator: "|")
        let netStateData = self.getNetState()
        
        return NetworkReport(offline: offline.duration,
                             wifi: wifi.duration,
                             cellular: netStateData.celluler,
                             ethernet: ethernet.duration,
                             other: other.duration,
                             netState: netStateData.netState, 
                             netSource: netSource)
    }
    
    private func getNetState() -> (celluler: Millisecond, netState: String){
        
        var nstString = BlueTriangle.networkStateMonitor?.state.value?.description.lowercased() ?? ""
        let offline = offline.duration
        let wifi = wifi.duration
        let cellular5G = cellular5g.duration
        let cellular4G = cellular4g.duration
        let cellular3G = cellular3g.duration
        let cellular2G = cellular2g.duration
        let cellularUnknown = cellularUnknown.duration
        let ethernet = ethernet.duration
        let other = other.duration
        let totalCellulerUsed = cellular5G + cellular4G + cellular3G + cellular2G + cellularUnknown
        let maxNetUsed = max(wifi, totalCellulerUsed, ethernet, offline, other)
        let maxCellulerUsedTechnology = max(cellular5G, cellular4G, cellular3G, cellular2G, cellularUnknown)
        
        if maxNetUsed > 0{
            
            if maxNetUsed == wifi{
                nstString = NetworkState.Wifi.description.lowercased()
            }else if maxNetUsed == totalCellulerUsed{
                if maxCellulerUsedTechnology == cellular5G{
                    nstString = NetworkState.Cellular(._5G).description.lowercased()
                }else if maxCellulerUsedTechnology == cellular4G{
                    nstString = NetworkState.Cellular(._4G).description.lowercased()
                }else if maxCellulerUsedTechnology == cellular3G{
                    nstString = NetworkState.Cellular(._3G).description.lowercased()
                }else if maxCellulerUsedTechnology == cellular2G{
                    nstString = NetworkState.Cellular(._2G).description.lowercased()
                }else{
                    nstString = NetworkState.Cellular(._Unknown).description.lowercased()
                }
            }else if maxNetUsed == ethernet{
                nstString = NetworkState.Ethernet.description.lowercased()
            }else if maxNetUsed == offline{
                nstString = NetworkState.Offline.description.lowercased()
            }else{
                nstString = NetworkState.Other.description.lowercased()
            }
        }
               
        return (totalCellulerUsed, nstString)
    }
    
    private func updateStopWatch(_ type : NetworkState?){
        
        // Save previous network type data
        if let previousType = currentNetwork{
            
            switch previousType {
            case .Wifi:
                wifi.stop()
            case .Cellular(let type):
                switch type {
                case ._5G:
                    cellular5g.stop()
                case ._4G:
                    cellular4g.stop()
                case ._3G:
                    cellular3g.stop()
                case ._2G:
                    cellular2g.stop()
                case ._Unknown:
                    cellularUnknown.stop()
                }
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
            case .Cellular(let type):
                switch type {
                case ._5G:
                    cellular5g.start()
                case ._4G:
                    cellular4g.start()
                case ._3G:
                    cellular3g.start()
                case ._2G:
                    cellular2g.start()
                case ._Unknown:
                    cellularUnknown.start()
                }
            case .Ethernet:
                ethernet.start()
            case .Other:
                other.start()
            case .Offline:
                offline.start()
            }
        }
    }
    
    deinit{
        self.cancellable = nil
        self.sourceCancellable = nil
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
    let netState: String
    let netSource: String
}

