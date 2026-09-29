//
//  BTTEvents.swift
//  blue-triangle
//
//  Created by Ashok Singh on 02/02/26.
//

internal struct BTTEvents {

    static let coldLaunch = BTTEvent(
        id: BTTEventId.coldLaunch.rawValue,
        defaultPageName: BTTEventDefaultPageName.coldLaunchPage.rawValue
    )

    static let hotLaunch = BTTEvent(
        id: BTTEventId.hotLaunch.rawValue,
        defaultPageName: BTTEventDefaultPageName.hotLaunchPage.rawValue
    )

    static let anrWarning = BTTEvent(
        id: BTTEventId.anrWarning.rawValue,
        defaultPageName: BTTEventDefaultPageName.anrWarning.rawValue
    )

    static let memoryWarning = BTTEvent(
        id: BTTEventId.memoryWarning.rawValue,
        defaultPageName: BTTEventDefaultPageName.memoryWarning.rawValue
    )

    static let nativeAppCrash = BTTEvent(
        id: BTTEventId.nativeAppCrash.rawValue,
        defaultPageName: BTTEventDefaultPageName.nativeAppCrash.rawValue
    )
    
    static let appInstall = BTTEvent(
        id: BTTEventId.appInstall.rawValue,
        defaultPageName: BTTEventDefaultPageName.appInstall.rawValue
    )
    
    static let forceRestart = BTTEvent(
        id: BTTEventId.forceRestart.rawValue,
        defaultPageName: BTTEventDefaultPageName.forceRestart.rawValue
    )

    static let excessCPUUsage = BTTEvent(
        id: BTTEventId.excessCPUUsage.rawValue,
        defaultPageName: BTTEventDefaultPageName.excessCPUUsage.rawValue
    )

    static let heavyDiskWrite = BTTEvent(
        id: BTTEventId.heavyDiskWrite.rawValue,
        defaultPageName: BTTEventDefaultPageName.heavyDiskWrite.rawValue
    )

    static let slowLaunch = BTTEvent(
        id: BTTEventId.slowLaunch.rawValue,
        defaultPageName: BTTEventDefaultPageName.slowLaunch.rawValue
    )
}

internal struct BTTEvent {
    let id : String
    let defaultPageName : String
}

internal enum BTTEventDefaultPageName : String {
    case coldLaunchPage      = "ColdLaunchTime"
    case hotLaunchPage       = "HotLaunchTime"
    case anrWarning          = "ANRWarning"
    case memoryWarning       = "MemoryWarning"
    case nativeAppCrash      = "NativeAppCrash"
    case appInstall          = "AppInstall"
    case forceRestart        = "ForceRestart"
    case excessCPUUsage      = "ExcessCPUUsage"
    case heavyDiskWrite      = "HeavyDiskWrite"
    case slowLaunch          = "SlowLaunch"
}

internal enum BTTEventId: String {
    case coldLaunch    = "1"
    case hotLaunch     = "3"
    case anrWarning    = "4"
    case memoryWarning = "5"
    case nativeAppCrash = "6"
    case appInstall    = "8"
    case forceRestart  = "15"
    case excessCPUUsage = "16"
    case heavyDiskWrite = "17"
    case slowLaunch     = "18"
}
