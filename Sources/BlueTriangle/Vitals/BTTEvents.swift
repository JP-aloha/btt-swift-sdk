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
}

internal struct BTTEvent {
    let id : String
    let defaultPageName : String
}

internal enum BTTEventDefaultPageName : String {
    case coldLaunchPage = "ColdLaunchTime"
    case hotLaunchPage  = "HotLaunchTime"
    case anrWarning     = "ANRWarning"
    case memoryWarning  = "MemoryWarning"
    case iOSCrash       = "iOS Crash"
}

internal enum BTTEventId: String {
    case coldLaunch    = "1"
    case hotLaunch     = "3"
    case anrWarning    = "4"
    case memoryWarning = "5"
    case iOSCrash      = "6"
}
