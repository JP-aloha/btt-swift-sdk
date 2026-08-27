//
//  CrashReportManaging.swift
//
//  Created by Mathew Gacy on 4/11/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

protocol CrashReportManaging {
    func uploadError<E: Error>(_ error: E, file: StaticString, function: StaticString, line: UInt)
    func logFatalError<E: Error>(_ error: E, file: StaticString, function: StaticString, line: UInt)
    func uploadErrorForPage(pageName: String, uuid: UUID, segment : String, pageType: String)
    func stop()
}
