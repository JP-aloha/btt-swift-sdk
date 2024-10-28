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
    case Manual
}

enum NativeAppType : CustomStringConvertible, Encodable, Decodable{
    case Regular
    case NST
    
    public var description: String {
        switch self {
        case .Regular:
            return "regular"
        case .NST:
            return "nst"
        }
    }
}

struct NativeAppProperties: Equatable {
    let fullTime: Millisecond
    let loadTime: Millisecond
    let maxMainThreadUsage: Millisecond
    let numberOfCPUCores: Int32 = Int32(ProcessInfo.processInfo.activeProcessorCount)
    let viewType: ViewType?
    let offline: Millisecond
    let wifi: Millisecond
    let cellular: Millisecond
    let ethernet: Millisecond
    let other: Millisecond
    var err: String?
    var type : String = NativeAppType.Regular.description
    var netState: String = BlueTriangle.monitorNetwork?.state.value?.description.lowercased() ?? ""
    var deviceModel : String = Device.model
    var netStateSource : String = BlueTriangle.monitorNetwork?.networkSource.value?.description ?? ""
}

extension NativeAppProperties: Codable{
    
    func encode(to encoder: Encoder) throws {
        var con = encoder.container(keyedBy: CodingKeys.self)
       
        if fullTime > 0{
            try con.encode(fullTime, forKey: .fullTime)
        }
        
        if loadTime > 0{
            try con.encode(loadTime, forKey: .loadTime)
        }
        
        if self.type != NativeAppType.NST.description{
            try con.encode(maxMainThreadUsage, forKey: .maxMainThreadUsage)
        }
        
        if self.type != NativeAppType.NST.description{
            try con.encode(numberOfCPUCores, forKey: .numberOfCPUCores)
        }
                
        if viewType != nil{
            try con.encode(viewType, forKey: .viewType)
        }
        
        if offline > 0{
            try con.encode(offline, forKey: .offline)
        }
        if wifi > 0{
            try con.encode(wifi, forKey: .wifi)
        }
        if cellular > 0{
            try con.encode(cellular, forKey: .cellular)
        }
        if ethernet > 0{
            try con.encode(ethernet, forKey: .ethernet)
        }
        if other > 0{
            try con.encode(other, forKey: .other)
        }
        
        if let err = err, err.count > 0{
            try con.encode(err, forKey: .err)
        }
    
        if netState.count > 0{
            try con.encode(netState, forKey: .netState)
        }
        
        if netStateSource.count > 0{
            try con.encode(netStateSource, forKey: .netStateSource)
        }
        
        try con.encode(deviceModel, forKey: .deviceModel)
    }
    
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.fullTime = try container.decodeIfPresent(Millisecond.self, forKey: .fullTime)  ?? 0
        self.loadTime = try container.decodeIfPresent(Millisecond.self, forKey: .loadTime)  ?? 0
        self.maxMainThreadUsage = try container.decodeIfPresent(Millisecond.self, forKey: .maxMainThreadUsage)  ?? 0
        self.viewType = try container.decodeIfPresent(ViewType.self, forKey: .viewType)
        self.wifi = try container.decodeIfPresent(Millisecond.self, forKey: .wifi)  ?? 0
        self.offline = try container.decodeIfPresent(Millisecond.self, forKey: .offline)  ?? 0
        self.cellular = try container.decodeIfPresent(Millisecond.self, forKey: .cellular)  ?? 0
        self.ethernet = try container.decodeIfPresent(Millisecond.self, forKey: .ethernet)  ?? 0
        self.other = try container.decodeIfPresent(Millisecond.self, forKey: .other) ?? 0
        self.netState = try container.decodeIfPresent(String.self, forKey: .netState) ?? ""
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? NativeAppType.NST.description
        self.deviceModel = try container.decodeIfPresent(String.self, forKey: .deviceModel) ?? Device.model
        self.netStateSource = try container.decodeIfPresent(String.self, forKey: .netStateSource) ?? ""
    }
    
    enum CodingKeys: String, CodingKey {
        case fullTime
        case loadTime
        case maxMainThreadUsage
        case numberOfCPUCores
        case viewType
        case offline
        case wifi
        case cellular
        case ethernet
        case netState
        case other
        case type
        case err
        case deviceModel
        case netStateSource
    }
}

extension NativeAppProperties {
    
    static func `init`(_ error : String?) -> Self{
        return  .init(
            fullTime: 0,
            loadTime: 0,
            maxMainThreadUsage: 0,
            viewType: nil,
            offline: 0,
            wifi: 0,
            cellular: 0,
            ethernet: 0,
            other: 0,
            err: error,
            type: NativeAppType.NST.description)
    }
    
    static var empty: Self = .init(
        fullTime: 0,
        loadTime: 0,
        maxMainThreadUsage: 0,
        viewType: nil,
        offline: 0,
        wifi: 0,
        cellular: 0,
        ethernet: 0,
        other: 0)
    
    static var nstEmpty: Self {
        .init(
            fullTime: 0,
            loadTime: 0,
            maxMainThreadUsage: 0,
            viewType: nil,
            offline: 0,
            wifi: 0,
            cellular: 0,
            ethernet: 0,
            other: 0,
            type: NativeAppType.NST.description)
    }
    
   
    func copy(_ type : NativeAppType) ->NativeAppProperties{
        return .init(
            fullTime: self.fullTime,
            loadTime: self.loadTime,
            maxMainThreadUsage: self.maxMainThreadUsage,
            viewType: self.viewType,
            offline: self.offline,
            wifi: self.wifi,
            cellular: self.cellular,
            ethernet: self.ethernet,
            other: self.other,
            type: type.description,
            netState: self.netState,
            deviceModel: self.deviceModel)
    }
}
