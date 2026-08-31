//
//  ErrorReport.swift
//
//  Created by Mathew Gacy on 3/28/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

struct ErrorReport: Codable {
    let eCnt: Int 
    let ver: String = Device.sdkVersion
    var nativeApp : NativeAppProperties = .nstEmpty
    let appName: String = Bundle.main.appName ?? "Unknown"
    let eTp: String
    let message: String
    let line: Int
    let column: Int
    let time: Millisecond
    
    func encode(to encoder: Encoder) throws {
        var con = encoder.container(keyedBy: CodingKeys.self)
        try con.encode(eCnt, forKey: .eCnt)
        try con.encode(eTp, forKey: .eTp)
        try con.encode(ver, forKey: .ver)
        try con.encode(nativeApp, forKey: .nativeApp)
        try con.encode(appName, forKey: .appName)
        try con.encode(message, forKey: .message)
        try con.encode(line, forKey: .line)
        try con.encode(column, forKey: .column)
        try con.encode(time, forKey: .time)
    }
        
    enum CodingKeys: String, CodingKey {
        case eCnt
        case eTp
        case nativeApp = "NATIVEAPP"
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
        time: Millisecond,
        eCnt : Int = 1
    ) {
        self.eTp = eTp
        self.eCnt = eCnt
        self.message = String(describing: error)
        self.line = Int(line)
        self.column = 1
        self.time = time
    }
    
    init(
        nativeApp : NativeAppProperties,
        eTp: String = BT_ErrorType.NativeAppCrash.rawValue,
        error: Error,
        line: UInt,
        time: Millisecond,
        eCnt : Int = 1
    ) {
        self.nativeApp = nativeApp
        self.eTp = eTp
        self.eCnt = eCnt
        self.message = error.localizedDescription
        self.line = Int(line)
        self.column = 1
        self.time = time
    }
}
