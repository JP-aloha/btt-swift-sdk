//
//  BTTSavedRemoteConfig.swift
//  
//
//  Created by Ashok Singh on 05/09/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//


import Foundation

class BTTSavedRemoteConfig: BTTRemoteConfig {
    var dateSaved: Millisecond

    init(networkSampleRateSDK: Int?,
         enableRemoteConfigAck : Bool?,
         dateSaved: Millisecond) {
        self.dateSaved = dateSaved
        super.init(networkSampleRateSDK: networkSampleRateSDK, enableRemoteConfigAck: enableRemoteConfigAck)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dateSaved = try container.decode(Millisecond.self, forKey: .dateSaved)
        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dateSaved, forKey: .dateSaved)
        try super.encode(to: encoder)
    }

    private enum CodingKeys: String, CodingKey {
        case dateSaved
    }
}
