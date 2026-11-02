//
//  BlueTriangle+TrackingSummary.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import Foundation

extension BlueTriangle {

    private static var hasLoggedTrackingSummary = false

    static func logTrackingSummary() {
        func rate(_ value: Double) -> String {
            "\(Int((value * 100).rounded()))%"
        }

        func toSentenceList(_ items: [String]) -> String {
            guard items.count > 1 else { return items.joined() }
            return items.dropLast().joined(separator: ", ") + " and " + items.last!
        }

        func captureLine(_ label: String, sampleRate: Double, isSampled: Bool, captured: String) -> String {
            isSampled
                ? "\(label): sampled at \(rate(sampleRate)), capturing \(captured)"
                : "\(label): not sampled at \(rate(sampleRate)), \(captured) not captured for this session"
        }

        struct ErrorType {
            let name: String
            let isEnabled: Bool
            let isSupported: Bool

            init(_ name: String, _ isEnabled: Bool, _ isSupported: Bool = true) {
                self.name = name
                self.isEnabled = isEnabled
                self.isSupported = isSupported
            }
        }

        func errorLine(_ label: String, sampleRate: Double, isSampled: Bool, types: [ErrorType]) -> String {
            let active = types.filter { $0.isEnabled && $0.isSupported }.map { $0.name }
            let disabled = types.filter { !$0.isEnabled }.map { $0.name }
            let unsupported = types.filter { $0.isEnabled && !$0.isSupported }.map { $0.name }

            var line: String
            if active.isEmpty {
                line = "\(label): \(isSampled ? "sampled" : "not sampled") at \(rate(sampleRate)), nothing to capture"
            } else {
                line = captureLine(label, sampleRate: sampleRate, isSampled: isSampled, captured: toSentenceList(active))
            }
            if !disabled.isEmpty {
                line += ". Tracking is disabled for \(toSentenceList(disabled)), so they will not be captured"
            }
            if !unsupported.isEmpty {
                line += ". Tracking for \(toSentenceList(unsupported)) requires a newer iOS version and is not available on this device"
            }
            return line + "."
        }

        let isMetricKitSupported: Bool = {
            if #available(iOS 14.0, *) { return true } else { return false }
        }()
        let isHangSupported: Bool = {
            if #available(iOS 15.0, *) { return true } else { return false }
        }()
        let isSlowLaunchSupported: Bool = {
            if #available(iOS 16.0, *) { return true } else { return false }
        }()
        let crashTrackingEnabled = configuration.crashTracking == .nsException

        let fatalErrors = [
            ErrorType("crashes", crashTrackingEnabled)
        ]

        let nonFatalErrors = [
            ErrorType("ANR warnings", configuration.ANRMonitoring),
            ErrorType("memory warnings", configuration.enableMemoryWarning),
            ErrorType("force restarts", configuration.enableForceRestart),
            ErrorType("network errors", true),
            ErrorType("hangs", crashTrackingEnabled, isHangSupported),
            ErrorType("excessive CPU usage", crashTrackingEnabled, isMetricKitSupported),
            ErrorType("heavy disk writes", crashTrackingEnabled, isMetricKitSupported),
            ErrorType("slow launches", crashTrackingEnabled, isSlowLaunchSupported)
        ]

        guard !hasLoggedTrackingSummary else { return }
        hasLoggedTrackingSummary = true

        let currentSessionID = session()?.sessionID ?? Identifier()

        let summary = [
            "Blue Triangle tracking active · SDK \(sdkVersion) · Site ID \(configuration.siteID) · Session ID \(currentSessionID)",
            configuration.enableScreenTracking
                ? "Screen tracking: enabled, capturing screen views."
                : "Screen tracking: disabled. Tracking is disabled for screen views, so they will not be captured.",
            captureLine("Network tracking", sampleRate: configuration.networkSampleRate, isSampled: shouldCaptureRequests, captured: "network requests") + ".",
            errorLine("Fatal errors", sampleRate: configuration.fatalErrorSampleRate, isSampled: shouldReportFatalErrors, types: fatalErrors),
            errorLine("Non-fatal errors", sampleRate: configuration.nonFatalErrorSampleRate, isSampled: shouldReportNonFatalErrors, types: nonFatalErrors)
        ].joined(separator: "\n")

        BTLogger.live.info(summary)
    }
}
