//
//  Logging.swift
//
//  Created by Mathew Gacy on 4/11/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

protocol Logging {
    var enableDebug: Bool { get set }

    func logDebug(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    )

    func logInfo(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    )

    func logDefault(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    )

    func logError(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}

extension Logging {
    func debug(
        _ message: @autoclosure @escaping () -> String,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        logDebug(message, file: file, function: function, line: line)
    }

    func info(
        _ message: @autoclosure @escaping () -> String,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        logInfo(message, file: file, function: function, line: line)
    }

    func log(
        _ message: @autoclosure @escaping () -> String,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        logDefault(message, file: file, function: function, line: line)
    }

    func error(
        _ message: @autoclosure @escaping () -> String,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        logError(message, file: file, function: function, line: line)
    }
}
