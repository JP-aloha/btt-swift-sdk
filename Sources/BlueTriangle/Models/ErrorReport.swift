//
//  ErrorReport.swift
//
//  Created by Mathew Gacy on 3/28/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

struct ErrorReport: Codable {
    let eCnt: Int = 1
    let ver: String = Version.number
    let appName: String = Bundle.main.appName ?? "Unknown"
    let eTp: String
    let message: String
    let line: Int
    let column: Int
    let time: Millisecond

    enum CodingKeys: String, CodingKey {
        case eCnt
        case eTp
        case ver = "VER"
        case appName = "url"
        case message = "msg"
        case line
        case column = "col"
        case time
    }
}

extension ErrorReport {
    init(
        eTp: String = BT_ErrorType.NativeAppCrash.rawValue,
        error: Error,
        line: UInt,
        time: Millisecond
    ) {
        self.eTp = eTp
        self.message = String(describing: error)
        self.line = Int(line)
        self.column = 1
        self.time = time
    }
}
