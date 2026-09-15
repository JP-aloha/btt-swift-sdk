//
//  EMetaBuilder.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import Foundation

/// Identifies which subsystem produced an error/crash report - the first field in every `eMeta`
/// string this SDK sends.
enum EMetaSource: String {
    case anrWatchDog = "ANRWatchDog"
    case memoryWarning = "OSMemoryWarning"
    case forceRestart = "ForceRestartTracker"
    case nsException = "nsException"
    case externalError = "ExternalError"
    case metricKit = "MetricKit"
}

enum EMetaBuilder {
    static func build(source: EMetaSource, build: String, arch: String, extraPairs: [String] = []) -> String {
        var pairs = [
            "source: \"\(source.rawValue)\"",
            "platform: \"\(Device.os)\"",
            "build: \"\(build)\"",
            "arch: \"\(arch)\""
        ]
        pairs.append(contentsOf: extraPairs)
        return "[\(pairs.joined(separator: ", "))]"
    }

    /// This app binary's own build version - for contexts with no MXDiagnostic to read one from.
    static var currentBuild: String {
        Bundle.main.buildVersionNumber ?? ""
    }

    /// This app binary's own compiled architecture - for contexts with no MXDiagnostic to read one
    /// from (MetricKit's `diagnostic.metaData.platformArchitecture` reports the device's, not this).
    static var currentArch: String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }
}
