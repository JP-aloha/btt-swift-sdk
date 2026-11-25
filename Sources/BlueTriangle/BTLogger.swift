//
//  BTLogger.swift
//
//  Created by Mathew Gacy on 11/2/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import os.log

// MARK: - SystemLogging

// https://stackoverflow.com/a/62488271/4472195
fileprivate extension OSLog {
    // swiftlint:disable:next identifier_name
    func callAsFunction(_ s: String) {
        os_log("%{public}s", log: self, s)
    }
}

struct OSLogWrapper: SystemLogging {
    private let logger: OSLog

    init(subsystem: String, category: String) {
        self.logger = OSLog(subsystem: subsystem, category: category)
    }

    func log(
        level: OSLogType,
        message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        logger.callAsFunction("\(function):\(line) - \(message())")
    }
}

@available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
struct LoggerWrapper: SystemLogging {
    private let logger: Logger

    init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    func log(
        level: OSLogType,
        message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        logger.log(level: level, "\(function):\(line) - \(message())")
    }
}

// MARK: - BTLogger

final class BTLogger: Logging {
    private let logger: SystemLogging
    var enableDebug: Bool

    init(logger: SystemLogging, enableDebug: Bool) {
        self.logger = logger
        self.enableDebug = enableDebug
    }

    init(enableDebug: Bool = false) {
        self.enableDebug = enableDebug
        if #available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *) {
            self.logger = LoggerWrapper(subsystem: Constants.loggingSubsystem, category: Constants.loggingCategory)
        } else {
            self.logger = OSLogWrapper(subsystem: Constants.loggingSubsystem, category: Constants.loggingCategory)
        }
    }

    func logDebug(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        if enableDebug {
            log(level: .debug, listenerLevel: .debug, message: message, file: file, function: function, line: line)
        }
    }

    func logInfo(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        log(level: .info, listenerLevel: .info, message: message, file: file, function: function, line: line)
    }

    func logDefault(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        log(level: .default, listenerLevel: .default, message: message, file: file, function: function, line: line)
    }

    func logError(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        log(level: .error, listenerLevel: .error, message: message, file: file, function: function, line: line)
    }

    private func log(
        level: OSLogType,
        listenerLevel: BTTLogLevel,
        message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        guard let listener = BlueTriangle.logListener else {
            logger.log(level: level, message: message, file: file, function: function, line: line)
            return
        }
        let text = message()
        logger.log(level: level, message: { text }, file: file, function: function, line: line)
        listener(listenerLevel, "\(function):\(line) - \(text)")
    }
}

extension BTLogger {
    static let live: Logging = {
        BTLogger()
    }()
}
