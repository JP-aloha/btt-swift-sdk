//
//  MXCallStackTreeProviding.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

#if os(iOS)
import MetricKit

/// Apple gives `callStackTree` no common home on `MXDiagnostic` - each diagnostic subclass redeclares
/// it - so this protocol unifies them for generic handling in `MetricKitWatchDog`.
@available(iOS 14.0, *)
protocol MXCallStackTreeProviding {
    var callStackTree: MXCallStackTree { get }
}

@available(iOS 14.0, *)
extension MXCrashDiagnostic: MXCallStackTreeProviding {}
@available(iOS 14.0, *)
extension MXCPUExceptionDiagnostic: MXCallStackTreeProviding {}
@available(iOS 14.0, *)
extension MXDiskWriteExceptionDiagnostic: MXCallStackTreeProviding {}
@available(iOS 15.0, *)
extension MXHangDiagnostic: MXCallStackTreeProviding {}
@available(iOS 16.0, *)
extension MXAppLaunchDiagnostic: MXCallStackTreeProviding {}
#endif
