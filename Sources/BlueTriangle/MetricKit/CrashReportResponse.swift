//
//  CrashReportResponse.swift
//
//  Created by JP on 18/07/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.

import Foundation

// MARK: - CrashReport
struct MetricKitCrashReport: Codable {
    let version: String
    let callStackTree: CallStackTree
    let diagnosticMetaData: DiagnosticMetaData
}

// MARK: - CallStackTree
struct CallStackTree: Codable {
    let callStacks: [CallStack]
    let callStackPerThread: Bool
}

// MARK: - CallStack
struct CallStack: Codable {
    let threadAttributed: Bool
    let callStackRootFrames: [CallStackRootFrame]
    
}

// MARK: - CallStackRootFrame
struct CallStackRootFrame: Codable {
    let binaryUUID: String
    let offsetIntoBinaryTextSegment, sampleCount: Int
    let subFrames: [CallStackRootFrame]?
    let binaryName: String
    let address: Int
   
}

// MARK: - DiagnosticMetaData
struct DiagnosticMetaData: Codable {
    let appBuildVersion, appVersion, regionFormat: String
    let exceptionType: Int
    let osVersion, deviceType, bundleIdentifier: String
    let exceptionCode, signal: Int
    let platformArchitecture: String
    let lowPowerModeEnabled: Bool?
    let isTestFlightApp: Bool?
}
