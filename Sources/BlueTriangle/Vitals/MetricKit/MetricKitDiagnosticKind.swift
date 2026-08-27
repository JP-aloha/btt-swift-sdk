//
//  MetricKitDiagnosticKind.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

#if os(iOS)
enum MetricKitDiagnosticKind {
    case crash
    case cpuException
    case diskWriteException
    case hang
    case slowLaunch

    var errorType: BT_ErrorType {
        switch self {
        case .crash: return .NativeAppCrash
        case .cpuException: return .ExcessCPUUsage
        case .diskWriteException: return .HeavyDiskWrite
        case .hang: return .ANRWarning
        case .slowLaunch: return .SlowLaunch
        }
    }

    var event: BTTEvent {
        switch self {
        case .crash: return BTTEvents.iOSCrash
        case .cpuException: return BTTEvents.cpuException
        case .diskWriteException: return BTTEvents.diskWriteException
        case .hang: return BTTEvents.anrWarning
        case .slowLaunch: return BTTEvents.slowAppLaunch
        }
    }
}
#endif
