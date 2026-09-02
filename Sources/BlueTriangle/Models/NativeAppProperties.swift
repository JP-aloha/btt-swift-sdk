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
    case NavigationTitle
    case LastChildName
    case Manual
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
    var responsivenessMeta: String?
    var responsivenessGrade: Int?
    var confidenceRate: Int32?
    var autoCheckout: Bool = false
    var confidenceMsg: String?
    var grouped: Bool?
    var err: String?
    var eventId: String?
    var installTime: Millisecond = 0
    var groupingCause: String?
    var groupNameSource: GroupSource?
    var breadcrumbs: String?
    var configKey: String?
    var groupingCauseInterval: Millisecond?
    var sdkVersion: String = Device.sdkVersion
    var sdkId: String = BlueTriangle.sdkId
    var appVersion: String = Device.appVersion
    var type : String = NativeAppType.Regular.description
    var netState: String = BlueTriangle.networkStateMonitor?.state.value?.description.lowercased() ?? ""
    var deviceModel : String = Device.model
    var netStateSource : String = BlueTriangle.networkStateMonitor?.networkSource.value?.description ?? ""
    /// Set only for MetricKit crash diagnostics - see MetricKitWatchDog+DiagnosticProcessing.reportCrash().
    var eMetadata: String?
    /// Set only for MetricKit crash diagnostics - see MetricKitWatchDog+DiagnosticProcessing.reportCrash().
    var eIdentifier: String?
    /// Set only for MetricKit diagnostics - the call stack, split off of the message's first two lines.
    /// See MetricKitWatchDog+DiagnosticProcessing.crashStyleMessage().
    var stackTrace: String?
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

        if let responsivenessMeta = responsivenessMeta, !responsivenessMeta.isEmpty {
            try con.encode(responsivenessMeta, forKey: .responsivenessMeta)
        }

        if let responsivenessGrade = responsivenessGrade {
            try con.encode(responsivenessGrade, forKey: .responsivenessGrade)
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

        if let groupNameSource = groupNameSource {
            try con.encode(groupNameSource, forKey: .groupNameSource)
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

        if let eMetadata = eMetadata, !eMetadata.isEmpty {
            try con.encode(eMetadata, forKey: .eMetadata)
        }

        if let eIdentifier = eIdentifier, !eIdentifier.isEmpty {
            try con.encode(eIdentifier, forKey: .eIdentifier)
        }

        if let stackTrace = stackTrace, !stackTrace.isEmpty {
            try con.encode(stackTrace, forKey: .stackTrace)
        }

        try con.encode(deviceModel, forKey: .deviceModel)
        try con.encode(appVersion, forKey: .appVersion)
        try con.encode(sdkVersion, forKey: .sdkVersion)
        try con.encode(sdkId, forKey: .sdkId)
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
        self.responsivenessMeta = try container.decodeIfPresent(String.self, forKey: .responsivenessMeta)
        self.responsivenessGrade = try container.decodeIfPresent(Int.self, forKey: .responsivenessGrade)
        self.netState = try container.decodeIfPresent(String.self, forKey: .netState) ?? ""
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? NativeAppType.NST.description
        self.deviceModel = try container.decodeIfPresent(String.self, forKey: .deviceModel) ?? Device.model
        self.appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion) ?? Device.appVersion
        self.sdkVersion = try container.decodeIfPresent(String.self, forKey: .sdkVersion) ?? Device.sdkVersion
        self.sdkId = try container.decodeIfPresent(String.self, forKey: .sdkId) ?? BlueTriangle.sdkId
        self.netStateSource = try container.decodeIfPresent(String.self, forKey: .netStateSource) ?? ""
        self.confidenceRate = try container.decodeIfPresent(Int32.self, forKey: .confidenceRate).flatMap { $0 > 0 ? $0 : nil }
        self.confidenceMsg = try container.decodeIfPresent(String.self, forKey: .confidenceMsg).flatMap { $0.isEmpty ? nil : $0 }
        self.groupingCause = try container.decodeIfPresent(String.self, forKey: .groupingCause).flatMap { $0.isEmpty ? nil : $0 }
        self.groupingCauseInterval = try container.decodeIfPresent(Millisecond.self, forKey: .groupingCauseInterval).flatMap { $0 > 0 ? $0 : nil }
        self.eventId = try container.decodeIfPresent(String.self, forKey: .eventID).flatMap { $0.isEmpty ? nil : $0 }
        self.screenCount = try container.decodeIfPresent(Int32.self, forKey: .screenCount)
        self.httpMethod = try container.decodeIfPresent(String.self, forKey: .httpMethod)
        self.confidenceRate = try container.decodeIfPresent(Int32.self, forKey: .confidenceRate) ?? 0
        self.confidenceMsg = try container.decodeIfPresent(String.self, forKey: .confidenceMsg) ?? ""
        self.groupingCause = try container.decodeIfPresent(String.self, forKey: .groupingCause) ?? ""
        self.groupNameSource = try container.decodeIfPresent(GroupSource.self, forKey: .groupNameSource)
        self.groupingCauseInterval = try container.decodeIfPresent(Millisecond.self, forKey: .groupingCauseInterval) ?? 0
        self.autoCheckout = try container.decodeIfPresent(Bool.self, forKey: .autoCheckout) ?? false
        self.breadcrumbs = try container.decodeIfPresent(String.self, forKey: .breadcrumbs).flatMap { $0.isEmpty ? nil : $0 }
        self.installTime = try container.decodeIfPresent(Millisecond.self, forKey: .installTime)  ?? 0
        self.configKey = try container.decodeIfPresent(String.self, forKey: .configKey).flatMap { $0.isEmpty ? nil : $0 }
        self.eMetadata = try container.decodeIfPresent(String.self, forKey: .eMetadata)
        self.eIdentifier = try container.decodeIfPresent(String.self, forKey: .eIdentifier)
        self.stackTrace = try container.decodeIfPresent(String.self, forKey: .stackTrace)
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
        case responsivenessMeta
        case responsivenessGrade
        case type
        case err
        case deviceModel
        case netStateSource
        case screenCount
        case httpMethod
        case appVersion
        case grouped
        case sdkVersion
        case sdkId
        case confidenceRate
        case confidenceMsg
        case groupingCause
        case groupNameSource
        case groupingCauseInterval
        case eventID
        case autoCheckout
        case breadcrumbs
        case installTime
        case configKey
        case eMetadata
        case eIdentifier
        case stackTrace
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
