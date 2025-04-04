//
//  File.swift
//
//
//  Created by Ashok Singh on 31/03/25.
//

import Foundation

class ClaritySessionConnector {
    
    private let logger: Logging
    
    init(logger: Logging) {
        self.logger = logger
    }
    
    func refreshClaritySessionUrlCustomVariable(){
        if let claritySessionUrl = self.getClaritySessionUrl(){
            self.setClaritySessionUrlToCustomVariable(claritySessionUrl)
        }else{
            self.removeClaritySessionUrlFromCustomVariable()
        }
    }
}

extension ClaritySessionConnector{
    
    private struct ClarityCVKeys {
        static let claritySessionURL = "CV0"
    }
    
    private struct ClarityReflectionKeys {
        static let getSessionUrl = "getCurrentSessionUrl"
        static let clarityClass = "Clarity.ClaritySDK"
    }
    
    private func setClaritySessionUrlToCustomVariable(_ claritySessionUrl : String) {
        BlueTriangle.setCustomVariable(ClarityCVKeys.claritySessionURL, value: claritySessionUrl)
        self.logger.info("BlueTriangle:ClaritySessionConnector : Updated clarity session URL: \(claritySessionUrl)")
    }
    
    private func removeClaritySessionUrlFromCustomVariable() {
        BlueTriangle.clearCustomVariable(ClarityCVKeys.claritySessionURL)
    }
    
    private func getClaritySessionUrl() -> String? {
        
        var claritySessionUrl : String?
        
        guard let clarityClass = NSClassFromString(ClarityReflectionKeys.clarityClass) as? NSObject.Type else {
            self.logger.info("BlueTriangle: \(ClarityReflectionKeys.clarityClass) class not found")
            return claritySessionUrl
        }
        
        let getSessionSelector = NSSelectorFromString(ClarityReflectionKeys.getSessionUrl)
        
        if clarityClass.responds(to: getSessionSelector) {
            if let clarityUrl = clarityClass.perform(getSessionSelector)?.takeUnretainedValue() as? String {
                claritySessionUrl = clarityUrl
            }
        }
        else{
            self.logger.info("BlueTriangle:ClaritySessionConnector : \(ClarityReflectionKeys.getSessionUrl) method not found")
        }
        
        return claritySessionUrl
    }
    
}
