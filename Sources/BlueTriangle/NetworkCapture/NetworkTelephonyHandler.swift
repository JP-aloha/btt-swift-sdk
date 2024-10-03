//
//  NetworkTelephonyHandler.swift
//  
//
//  Created by Ashok Singh on 26/09/24.
//

#if canImport(CoreTelephony)
import CoreTelephony
#endif
import Foundation

enum NetworkType: CustomStringConvertible {
    case _5G
    case _4G
    case _3G
    case _2G
    case _Unknown
    
    var description: String {
        switch self {
        case ._5G:
            return "Cellular 5G"
        case ._4G:
            return "Cellular 4G"
        case ._3G:
            return "Cellular 3G"
        case ._2G:
            return "Cellular 2G"
        case ._Unknown:
            return "Cellular"
        }
    }
}
protocol NetworkTelephonyProtocol{
    func observeNetworkType(_ completion :@escaping (String?)->())
    func getNetworkTechnology() -> String?
    func getNetworkType() -> NetworkType
}

class NetworkTelephonyHandler : NetworkTelephonyProtocol {
    
#if os(iOS)
    private let telephony: CTTelephonyNetworkInfo
#endif
    
    // iOS-specific initializer
#if os(iOS)
    init(_ telephony : CTTelephonyNetworkInfo = CTTelephonyNetworkInfo()) {
        self.telephony = telephony
    }
#else
    init() {}
#endif
    

    
    func observeNetworkType(_ completion :@escaping (String?)->()){
#if os(iOS)
        NotificationCenter
            .default
            .addObserver(forName: NSNotification.Name.CTServiceRadioAccessTechnologyDidChange,
                         object: nil,
                         queue: .main) { _ in
            if let technology = self.getNetworkTechnology() {
               completion(technology)
            }
        }
#else
        completion(nil)
#endif
    }
    
    func getNetworkTechnology() -> String? {
        
#if os(iOS)
        guard let technology = telephony.serviceCurrentRadioAccessTechnology?.values.first else {
            return nil
        }
        return technology
#else
        return nil
#endif
    }
    
    func getNetworkType() -> NetworkType {
        guard let technology = getNetworkTechnology() else {
            return ._Unknown
        }
        
#if os(iOS)
        if #available(iOS 14.1, *) {
            
            switch technology {
                
            case CTRadioAccessTechnologyNRNSA, CTRadioAccessTechnologyNR:
                return ._5G
            case CTRadioAccessTechnologyLTE:
                return ._4G
            case CTRadioAccessTechnologyWCDMA,
                CTRadioAccessTechnologyHSDPA,
            CTRadioAccessTechnologyHSUPA:
                return ._3G
            case CTRadioAccessTechnologyEdge,
            CTRadioAccessTechnologyGPRS:
                return ._2G
            case CTRadioAccessTechnologyCDMA1x,
                CTRadioAccessTechnologyCDMAEVDORev0,
                CTRadioAccessTechnologyCDMAEVDORevA,
            CTRadioAccessTechnologyCDMAEVDORevB:
                return ._2G
            default:
                return ._Unknown
            }
        }else{
            switch technology {
            case CTRadioAccessTechnologyLTE:
                return ._4G
            case CTRadioAccessTechnologyWCDMA,
                CTRadioAccessTechnologyHSDPA,
            CTRadioAccessTechnologyHSUPA:
                return ._3G
            case CTRadioAccessTechnologyEdge,
            CTRadioAccessTechnologyGPRS:
                return ._2G
            case CTRadioAccessTechnologyCDMA1x,
                CTRadioAccessTechnologyCDMAEVDORev0,
                CTRadioAccessTechnologyCDMAEVDORevA,
            CTRadioAccessTechnologyCDMAEVDORevB:
                return ._2G
            default:
                return ._Unknown
            }
        }
#else
        return ._Unknown
#endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
