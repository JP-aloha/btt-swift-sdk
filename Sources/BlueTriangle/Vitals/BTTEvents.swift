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

    static let iOSCrash = BTTEvent(
        id: BTTEventId.iOSCrash.rawValue,
        defaultPageName: BTTEventDefaultPageName.iOSCrash.rawValue
    )
    
    static let appInstall = BTTEvent(
        id: BTTEventId.appInstall.rawValue,
        defaultPageName: BTTEventDefaultPageName.appInstall.rawValue
    )
    
    static let forceRestart = BTTEvent(
        id: BTTEventId.forceRestart.rawValue,
        defaultPageName: BTTEventDefaultPageName.forceRestart.rawValue
    )

    static let cpuException = BTTEvent(
        id: BTTEventId.cpuException.rawValue,
        defaultPageName: BTTEventDefaultPageName.cpuException.rawValue
    )

    static let diskWriteException = BTTEvent(
        id: BTTEventId.diskWriteException.rawValue,
        defaultPageName: BTTEventDefaultPageName.diskWriteException.rawValue
    )

    static let slowAppLaunch = BTTEvent(
        id: BTTEventId.appLaunch.rawValue,
        defaultPageName: BTTEventDefaultPageName.slowAppLaunch.rawValue
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
    case iOSCrash            = "iOS Crash"
    case appInstall          = "AppInstall"
    case forceRestart        = "ForceRestart"
    case cpuException        = "ExcessCPUUsage"
    case diskWriteException  = "HeavyDiskWrite"
    case slowAppLaunch       = "SlowLaunch"
}

internal enum BTTEventId: String {
    case coldLaunch    = "1"
    case hotLaunch     = "3"
    case anrWarning    = "4"
    case memoryWarning = "5"
    case iOSCrash      = "6"
    case appInstall    = "8"
    case forceRestart  = "9"
    case cpuException       = "10"
    case diskWriteException = "11"
    case appLaunch          = "12"
}
