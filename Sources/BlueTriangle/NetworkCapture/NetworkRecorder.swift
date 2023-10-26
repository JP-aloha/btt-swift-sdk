//
//  NetworkRecorder.swift
//  
//
//  Created by Ashok Singh on 16/10/23.
//

import UIKit
import Combine

class NetworkRecorder {
    
    let offline = NetworkStateRecorder(type: .Offline)
    let wifi = NetworkStateRecorder(type: .Wifi)
    let cellular = NetworkStateRecorder(type: .Cellular)
    let ethernet = NetworkStateRecorder(type: .Ethernet)
    let other = NetworkStateRecorder(type: .Other)
   
    private var currentNetwork : Network?
    private var cancellable : AnyCancellable?
    
    func startNetworkObserver(){
        if let monitorNetwork = BlueTriangle.monitorNetwork {
            self.cancellable = monitorNetwork.$network
                .receive(on: RunLoop.main)
                .sink { _ in
                }receiveValue: { value in
                    self.updateNetworkRecording(value)
                }
        }
    }
    
    func stopNetworkObserver(){
        if let _ = BlueTriangle.monitorNetwork {
            self.updateNetworkRecording(nil)
            self.cancellable = nil
        }
    }
    
    private func updateNetworkRecording(_ type : Network?){
        
        // Save previous network type data
        if let previousType = currentNetwork{
            
            switch previousType {
            case .Wifi:
                wifi.stopRecording()
            case .Cellular:
                cellular.stopRecording()
            case .Ethernet:
                ethernet.stopRecording()
            case .Other:
                other.stopRecording()
            case .Offline:
                offline.stopRecording()
            }
        }
        
        // Start current network type data
        if let currentType = type{
           
            self.currentNetwork = type
            
            // Save previous network data
            switch currentType {
            case .Wifi:
                wifi.startRecording()
            case .Cellular:
                cellular.startRecording()
            case .Ethernet:
                ethernet.startRecording()
            case .Other:
                other.startRecording()
            case .Offline:
                offline.startRecording()
            }
        }
    }
}

class NetworkStateRecorder {
   
    private let type : Network
    private(set) var start : Millisecond = 0
    private(set) var totalTime : Millisecond = 0
    
    init(type: Network) {
        self.type = type
    }
    
    //Calculate and save
    func stopRecording(){
        totalTime = totalTime + (Date().timeIntervalSince1970.milliseconds - start)
        start = 0
    }
    
    //save network type start time
    func startRecording(){
        start = Date().timeIntervalSince1970.milliseconds
    }
}


struct NetworkReport: Codable, Equatable {
    let offline: Millisecond
    let wifi: Millisecond
    let cellular: Millisecond
    let ethernet: Millisecond
    let other: Millisecond
    
    init(_ recorder : NetworkRecorder ) {
        
        recorder.stopNetworkObserver()
        
        offline = recorder.offline.totalTime
        wifi = recorder.wifi.totalTime
        cellular = recorder.cellular.totalTime
        ethernet = recorder.ethernet.totalTime
        other = recorder.other.totalTime
    }
}

