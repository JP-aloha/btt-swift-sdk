//
//  BTTRemoteConfigHandler.swift
//  
//
//  Created by Ashok Singh on 09/09/24.
//

import Foundation

protocol RemoteConfigHandler {
    func updateRemoteConfig(_ config : BTTRemoteConfig)
}

class BTTRemoteConfigHandler : RemoteConfigHandler{

    func updateRemoteConfig(_ config : BTTRemoteConfig){
        updateSampleRate(config.wcdSamplePercent)
    }
    
    private func updateSampleRate(_ value : Int){
        let rate = Double(value) / 100.0
        BlueTriangle.updateNetworkSampleRate(rate)
    }
    
}
