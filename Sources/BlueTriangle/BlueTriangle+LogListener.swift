//
//  BlueTriangle+LogListener.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import Foundation

/// Severity of a log line forwarded to ``BlueTriangle/setLogListener(_:)``.
@objc
public enum BTTLogLevel: Int {
    case debug
    case info
    case `default`
    case error
}

extension BlueTriangle {
    private static let logListenerLock = NSLock()
    private static var _logListener: ((BTTLogLevel, String) -> Void)?

    static var logListener: ((BTTLogLevel, String) -> Void)? {
        logListenerLock.sync { _logListener }
    }

    /// Receives every SDK log line, e.g. to print or forward them. Pass `nil` to stop listening.
    @objc
    public static func setLogListener(_ listener: ((BTTLogLevel, String) -> Void)?) {
        logListenerLock.sync { _logListener = listener }
    }
}
