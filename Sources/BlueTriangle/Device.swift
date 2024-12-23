//
//  Device.swift
//
//  Created by Mathew Gacy on 10/13/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import class UIKit.UIDevice
#elseif os(watchOS)
import WatchKit
#endif

enum Device {
    /// The operating system name.
    static var os: String {
        #if os(iOS) || os(tvOS)
        return UIDevice.current.systemName
        #elseif os(watchOS)
        return WKInterfaceDevice.current().systemName
        #elseif os(macOS)
        return "macOS"
        #else
        return "UNKNOWN OS"
        #endif
    }

    /// The operating system version.
    static var osVersion: String {
        #if os(iOS) || os(tvOS)
        return UIDevice.current.systemVersion
        #elseif os(watchOS)
        return WKInterfaceDevice.current().systemVersion
        #elseif os(macOS)
        return ProcessInfo.processInfo.operatingSystemVersion.osVersionShort
        #else
        return ""
        #endif
    }

    /// The device model name.
    static var name: String {
        #if os(iOS) || os(tvOS)
        return UIDevice.current.name
        #elseif os(watchOS)
        return WKInterfaceDevice.current().model
        #elseif os(macOS)
        return platform()
        #endif
    }

    /// The BlueTriangle browser version.
    static var bvzn: String {
        "\(Constants.browser)-\(Bundle.main.releaseVersionNumber ?? "0.0")-\(os) \(osVersion)"
    }

    /// The User-Agent token.
    static var userAgentToken: String {
        "\(os)/\(osVersion) (\(model))"
    }
    
    /// Returns device model name.
    static var model : String {
       #if os(macOS)
        return  platform()
       #else
        return  deviceModel()
       #endif
   }
    
    /// Returns device model.
    private static func deviceModel() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0,  count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }


    /// Returns device name.
    private static func platform() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
}
