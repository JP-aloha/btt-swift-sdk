//
//  NativeAppProperties.swift
//  
//
//  Created by JP on 14/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

public enum ScreenType : String, Encodable, Decodable {
    case UIKit
    case SwiftUI
    case Manual
    case ReactNative
}

enum GroupSource: String, Encodable, Decodable {
    case title
    case custom
    case auto
}

enum NativeAppType : CustomStringConvertible, Encodable, Decodable{
    case Regular
    case NST
    
    internal var description: String {
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
    let loadStartTime: Millisecond
    let loadEndTime: Millisecond
    let maxMainThreadUsage: Millisecond
    let numberOfCPUCores: Int32 = Int32(ProcessInfo.processInfo.activeProcessorCount)
    let screenType: ScreenType?
    let offline: Millisecond
    let wifi: Millisecond
    let cellular: Millisecond
    let ethernet: Millisecond
    let other: Millisecond
    var hitchCount: Int64 = 0
    var totalHitchDuration: Millisecond = 0
    var longestHitch: Millisecond = 0
    var hangCount: Int64 = 0
    var totalHangDuration: Millisecond = 0
    var longestHang: Millisecond = 0
    var totalFrameCount: Int64 = 0
    var hitchHistograms: [HitchHistogramBucket] = HitchHistogramBucket.makeDefaultBuckets()
    var hitchesSeverity: Double = 0
    var confidenceRate: Int32?
    var autoCheckout: Bool = false
    var confidenceMsg: String?
    var grouped: Bool?
    var err: String?
    var eventId: String?
    var installTime: Millisecond = 0
    var groupingCause: String?
    var groupSource: GroupSource?
    var breadcrumbs: String?
    var configKey: String?
    var groupingCauseInterval: Millisecond?
    var sdkVersion: String = Device.sdkVersion
    var appVersion: String = Device.appVersion
    var type : String = NativeAppType.Regular.description
    var netState: String = BlueTriangle.networkStateMonitor?.state.value?.description.lowercased() ?? ""
    var deviceModel : String = Device.model
    var netStateSource : String = BlueTriangle.networkStateMonitor?.networkSource.value?.description ?? ""
    var screenCount: Int32?
    var httpMethod: String?
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
        
        if installTime > 0{
            try con.encode(installTime, forKey: .installTime)
        }
        
        if self.type != NativeAppType.NST.description{
            try con.encode(maxMainThreadUsage, forKey: .maxMainThreadUsage)
        }
        
        if self.type != NativeAppType.NST.description{
            try con.encode(numberOfCPUCores, forKey: .numberOfCPUCores)
        }
                
        if screenType != nil{
            try con.encode(screenType, forKey: .screenType)
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

        if hitchCount > 0 {
            try con.encode(hitchCount, forKey: .hitchCount)
        }

        if totalHitchDuration > 0 {
            try con.encode(totalHitchDuration, forKey: .totalHitchDuration)
        }

        if longestHitch > 0 {
            try con.encode(longestHitch, forKey: .longestHitch)
        }

        if hangCount > 0 {
            try con.encode(hangCount, forKey: .hangCount)
        }

        if totalHangDuration > 0 {
            try con.encode(totalHangDuration, forKey: .totalHangDuration)
        }

        if longestHang > 0 {
            try con.encode(longestHang, forKey: .longestHang)
        }

        if totalFrameCount > 0 {
            try con.encode(totalFrameCount, forKey: .totalFrameCount)
        }

        if hitchCount > 0 {
            try con.encode(HitchHistogramBucket.encodeCompact(hitchHistograms), forKey: .hitchHistograms)
            try con.encode(hitchesSeverity, forKey: .hitchesSeverity)
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
        
        if let screenCount = screenCount {
            try con.encode(screenCount, forKey: .screenCount)
        }

        if let httpMethod = httpMethod, !httpMethod.isEmpty {
            try con.encode(httpMethod.uppercased(), forKey: .httpMethod)
        }

        if let confidenceRate = confidenceRate {
            try con.encode(confidenceRate, forKey: .confidenceRate)
        }
        
        if let confidenceMsg = confidenceMsg {
            try con.encode(confidenceMsg, forKey: .confidenceMsg)
        }
        
        if let grouped = grouped {
            try con.encode(grouped, forKey: .grouped)
        }
        
        if let cause = groupingCause {
            try con.encode(cause, forKey: .groupingCause)
        }

        if let groupSource = groupSource {
            try con.encode(groupSource, forKey: .groupSource)
        }

        if let eventId = eventId, !eventId.isEmpty {
            try con.encode(eventId, forKey: .eventID)
        }
        
        if let interval  = groupingCauseInterval {
            try con.encode(interval, forKey: .groupingCauseInterval)
        }
        
        if autoCheckout {
            try con.encode(autoCheckout, forKey: .autoCheckout)
        }
        
        if let breadcrumbs  = breadcrumbs, !breadcrumbs.isEmpty {
            try con.encode(breadcrumbs, forKey: .breadcrumbs)
        }
        
        if let configKey  = configKey {
            try con.encode(configKey, forKey: .configKey)
        }
        
        try con.encode(deviceModel, forKey: .deviceModel)
        try con.encode(appVersion, forKey: .appVersion)
        try con.encode(sdkVersion, forKey: .sdkVersion)
    }
    
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.fullTime = try container.decodeIfPresent(Millisecond.self, forKey: .fullTime)  ?? 0
        self.loadTime = try container.decodeIfPresent(Millisecond.self, forKey: .loadTime)  ?? 0
        self.loadStartTime = try container.decodeIfPresent(Millisecond.self, forKey: .loadStartTime)  ?? 0
        self.loadEndTime = try container.decodeIfPresent(Millisecond.self, forKey: .loadEndTime)  ?? 0
        self.maxMainThreadUsage = try container.decodeIfPresent(Millisecond.self, forKey: .maxMainThreadUsage)  ?? 0
        self.screenType = try container.decodeIfPresent(ScreenType.self, forKey: .screenType)
        self.wifi = try container.decodeIfPresent(Millisecond.self, forKey: .wifi)  ?? 0
        self.offline = try container.decodeIfPresent(Millisecond.self, forKey: .offline)  ?? 0
        self.cellular = try container.decodeIfPresent(Millisecond.self, forKey: .cellular)  ?? 0
        self.ethernet = try container.decodeIfPresent(Millisecond.self, forKey: .ethernet)  ?? 0
        self.other = try container.decodeIfPresent(Millisecond.self, forKey: .other) ?? 0
        self.hitchCount = try container.decodeIfPresent(Int64.self, forKey: .hitchCount) ?? 0
        self.totalHitchDuration = try container.decodeIfPresent(Millisecond.self, forKey: .totalHitchDuration) ?? 0
        self.longestHitch = try container.decodeIfPresent(Millisecond.self, forKey: .longestHitch) ?? 0
        self.hangCount = try container.decodeIfPresent(Int64.self, forKey: .hangCount) ?? 0
        self.totalHangDuration = try container.decodeIfPresent(Millisecond.self, forKey: .totalHangDuration) ?? 0
        self.longestHang = try container.decodeIfPresent(Millisecond.self, forKey: .longestHang) ?? 0
        self.totalFrameCount = try container.decodeIfPresent(Int64.self, forKey: .totalFrameCount) ?? 0
        if let hitchHistogramsString = try container.decodeIfPresent(String.self, forKey: .hitchHistograms) {
            self.hitchHistograms = HitchHistogramBucket.decodeCompact(hitchHistogramsString)
        } else {
            self.hitchHistograms = HitchHistogramBucket.makeDefaultBuckets()
        }
        self.hitchesSeverity = try container.decodeIfPresent(Double.self, forKey: .hitchesSeverity) ?? 0
        self.netState = try container.decodeIfPresent(String.self, forKey: .netState) ?? ""
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? NativeAppType.NST.description
        self.deviceModel = try container.decodeIfPresent(String.self, forKey: .deviceModel) ?? Device.model
        self.appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion) ?? Device.appVersion
        self.sdkVersion = try container.decodeIfPresent(String.self, forKey: .sdkVersion) ?? Device.sdkVersion
        self.netStateSource = try container.decodeIfPresent(String.self, forKey: .netStateSource) ?? ""
        self.screenCount = try container.decodeIfPresent(Int32.self, forKey: .screenCount)
        self.httpMethod = try container.decodeIfPresent(String.self, forKey: .httpMethod)
        self.confidenceRate = try container.decodeIfPresent(Int32.self, forKey: .confidenceRate) ?? 0
        self.confidenceMsg = try container.decodeIfPresent(String.self, forKey: .confidenceMsg) ?? ""
        self.groupingCause = try container.decodeIfPresent(String.self, forKey: .groupingCause) ?? ""
        self.groupSource = try container.decodeIfPresent(GroupSource.self, forKey: .groupSource)
        self.groupingCauseInterval = try container.decodeIfPresent(Millisecond.self, forKey: .groupingCauseInterval) ?? 0
        self.eventId = try container.decodeIfPresent(String.self, forKey: .eventID) ?? ""
        self.autoCheckout = try container.decodeIfPresent(Bool.self, forKey: .autoCheckout) ?? false
        self.breadcrumbs = try container.decodeIfPresent(String.self, forKey: .breadcrumbs) ?? ""
        self.installTime = try container.decodeIfPresent(Millisecond.self, forKey: .installTime)  ?? 0
        self.configKey = try container.decodeIfPresent(String.self, forKey: .configKey) ?? ""
    }
    
    enum CodingKeys: String, CodingKey {
        case fullTime
        case loadTime
        case loadStartTime
        case loadEndTime
        case maxMainThreadUsage
        case numberOfCPUCores
        case screenType
        case offline
        case wifi
        case cellular
        case ethernet
        case netState
        case other
        case hitchCount
        case totalHitchDuration
        case longestHitch
        case hangCount
        case totalHangDuration
        case longestHang
        case totalFrameCount
        case hitchHistograms
        case hitchesSeverity
        case type
        case err
        case deviceModel
        case netStateSource
        case screenCount
        case httpMethod
        case appVersion
        case grouped
        case sdkVersion
        case confidenceRate
        case confidenceMsg
        case groupingCause
        case groupSource
        case groupingCauseInterval
        case eventID
        case autoCheckout
        case breadcrumbs
        case installTime
        case configKey
    }
}

extension NativeAppProperties {
    
    static func `init`(_ error : String?) -> Self{
        return  .init(
            fullTime: 0,
            loadTime: 0,
            loadStartTime: 0,
            loadEndTime: 0,
            maxMainThreadUsage: 0,
            screenType: nil,
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
        loadStartTime: 0,
        loadEndTime: 0,
        maxMainThreadUsage: 0,
        screenType: nil,
        offline: 0,
        wifi: 0,
        cellular: 0,
        ethernet: 0,
        other: 0)
    
    static var nstEmpty: Self {
        .init(
            fullTime: 0,
            loadTime: 0,
            loadStartTime: 0,
            loadEndTime: 0,
            maxMainThreadUsage: 0,
            screenType: nil,
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
            loadStartTime: self.loadStartTime,
            loadEndTime: self.loadEndTime,
            maxMainThreadUsage: self.maxMainThreadUsage,
            screenType: self.screenType,
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
