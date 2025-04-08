//
//  ClaritySessionConnector.swift
//
//
//  Created by Ashok Singh on 31/03/25..
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

class ClaritySessionConnector {
    
    private let logger: Logging
    private let isClarity : Bool = false
    private var clarityClass : NSObject.Type?
    
    init(logger: Logging) {
        self.logger = logger
        self.initializeClarityMethods()
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
    
    private func setClaritySessionUrlToCustomVariable(_ claritySessionUrl : String) {
        BlueTriangle.setCustomVariable(ClarityCVKeys.claritySessionURL, value: claritySessionUrl)
    }
    
    private func removeClaritySessionUrlFromCustomVariable() {
        BlueTriangle.clearCustomVariable(ClarityCVKeys.claritySessionURL)
    }
}

extension ClaritySessionConnector{
    
    private struct ClarityCVKeys {
        static let claritySessionURL = "CV0"
    }
    
    private struct ClaritySDKConstants {
        static let getSessionUrlMethod = "getCurrentSessionUrl"
        static let clarityClassName = "Clarity.ClaritySDK"
    }
    
    private func initializeClarityMethods(){
        
        if let clarityClass = NSClassFromString(ClaritySDKConstants.clarityClassName) as? NSObject.Type{
           
            let getSessionSelector = NSSelectorFromString(ClaritySDKConstants.getSessionUrlMethod)
            
            if clarityClass.responds(to: getSessionSelector) {
                self.clarityClass = clarityClass
                self.logger.info("BlueTriangle:ClaritySessionConnector : Clarity SDK found and setup successfully.")
            }else{
                self.logger.info("BlueTriangle:ClaritySessionConnector : \(ClaritySDKConstants.getSessionUrlMethod) method not found")
            }
        }
        else{
            self.logger.info("BlueTriangle: ClaritySessionConnector : Clarity SDK class \(ClaritySDKConstants.clarityClassName) not found")
        }
    }
    
    private func getClaritySessionUrl() -> String? {
        
        let getSessionSelector = NSSelectorFromString(ClaritySDKConstants.getSessionUrlMethod)
        
        if let clarity = self.clarityClass, let clarityUrl = clarity.perform(getSessionSelector)?.takeUnretainedValue() as? String{
            return clarityUrl
        }

        return nil
    }
}
