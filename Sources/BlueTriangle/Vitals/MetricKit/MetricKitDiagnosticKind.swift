//
//  MetricKitDiagnosticKind.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

#if os(iOS)
enum MetricKitDiagnosticKind {
    case crash
    case excessCPUUsage
    case heavyDiskWrite
    case hang
    case slowLaunch

    var errorType: BT_ErrorType {
        switch self {
        case .crash: return .NativeAppCrash
        case .excessCPUUsage: return .ExcessCPUUsage
        case .heavyDiskWrite: return .HeavyDiskWrite
        case .hang: return .ANRWarning
        case .slowLaunch: return .SlowLaunch
        }
    }

    var event: BTTEvent {
        switch self {
        case .crash: return BTTEvents.nativeAppCrash
        case .excessCPUUsage: return BTTEvents.excessCPUUsage
        case .heavyDiskWrite: return BTTEvents.heavyDiskWrite
        case .hang: return BTTEvents.anrWarning
        case .slowLaunch: return BTTEvents.slowLaunch
        }
    }
}
#endif
