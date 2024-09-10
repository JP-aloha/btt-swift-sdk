//
//  BTTRemoteConfigHandler.swift
//  
//
//  Created by Ashok Singh on 09/09/24.
//

import Foundation

protocol RemoteConfigHandler {
    func updateSampleRate(_ value : Int)
}

class BTTRemoteConfigHandler : RemoteConfigHandler{

    func updateSampleRate(_ value : Int){
        let rate = Double(value) / 100.0
        BlueTriangle.updateNetworkSampleRate(rate)
    }
}
