//
//  NativeAppProperties.swift
//  
//
//  Created by JP on 14/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

enum ViewType : String, Encodable, Decodable {
    case UIKit
    case SwiftUI
}

enum NativeAppType : String, Encodable, Decodable{
    case Regular
    case NST
}

struct NativeAppProperties: Equatable {
    let fullTime: Millisecond
    let loadTime: Millisecond
    let maxMainThreadUsage: Millisecond
    let viewType: ViewType?
    let offline: Millisecond
    let wifi: Millisecond
    let cellular: Millisecond
    let ethernet: Millisecond
    let other: Millisecond
    var type : NativeAppType = .Regular
    var nSt: String = BlueTriangle.monitorNetwork?.network.description ?? ""
}

extension NativeAppProperties: Codable{
    
    func encode(to encoder: Encoder) throws {
        var con = encoder.container(keyedBy: CodingKeys.self)
       
        var nstValue : Millisecond = 0
        var nstString = nSt
        
        
        if fullTime > 0{
            try con.encode(fullTime, forKey: .fullTime)
        }
        
        if loadTime > 0{
            try con.encode(loadTime, forKey: .loadTime)
        }
        
        if self.type != .NST{
            try con.encode(maxMainThreadUsage, forKey: .maxMainThreadUsage)
        }
                
        if viewType != nil{
            try con.encode(viewType, forKey: .viewType)
        }
        
        if offline > 0{
            nstString = offline > nstValue ? Network.Offline.description : nstString
            nstValue = offline > nstValue ? offline : nstValue
            try con.encode(offline, forKey: .offline)
        }
        if wifi > 0{
            nstString = wifi > nstValue ? Network.Wifi.description : nstString
            nstValue = wifi > nstValue ? wifi : nstValue
            try con.encode(wifi, forKey: .wifi)
        }
        if cellular > 0{
            nstString = cellular > nstValue ? Network.Cellular.description : nstString
            nstValue = cellular > nstValue ? cellular : nstValue
            try con.encode(cellular, forKey: .cellular)
        }
        if ethernet > 0{
            nstString = ethernet > nstValue ? Network.Ethernet.description : nstString
            nstValue = ethernet > nstValue ? ethernet : nstValue
            try con.encode(ethernet, forKey: .ethernet)
        }
        if other > 0{
            nstString = other > nstValue ? Network.Other.description : nstString
            nstValue = other > nstValue ? other : nstValue
            try con.encode(other, forKey: .other)
        }
    
        if nstString.count > 0{
            try con.encode(nstString, forKey: .nSt)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case fullTime
        case loadTime
        case maxMainThreadUsage
        case viewType
        case offline
        case wifi
        case cellular
        case ethernet
        case nSt
        case other
    }
}

extension NativeAppProperties {
    static let empty: Self = .init(
        fullTime: 0,
        loadTime: 0,
        maxMainThreadUsage: 0,
        viewType: nil,
        offline: 0,
        wifi: 0,
        cellular: 0,
        ethernet: 0,
        other: 0)
    
    static let nstEmpty: Self = .init(
        fullTime: 0,
        loadTime: 0,
        maxMainThreadUsage: 0,
        viewType: nil,
        offline: 0,
        wifi: 0,
        cellular: 0,
        ethernet: 0,
        other: 0,
        type: .NST)
}
