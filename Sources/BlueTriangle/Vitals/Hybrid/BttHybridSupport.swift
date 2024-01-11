//
//  BttHybridSupport.swift
//  
//
//  Created by Ashok Singh on 10/01/24.
//

import WebKit

public class BttHybridSupport {

    public let hybridSupport = BttHybridSupport()
    
    public func setupTrackerForWeb(_  webView : WKWebView){
        let sessionId = BlueTriangle.sessionID
        let expiration = NSString(string:"\(Date.addCurrentTimeInMinut(1800))")
        let BTTSessionValues = String(format: "{\"value\":\"%@\", \"expires\":\"%@\"}", sessionId, expiration)
        let sessionJavascript = String(format: "localStorage.setItem(\"%@\", JSON.stringify(%@))", "BTT_X0siD", BTTSessionValues)
        webView.evaluateJavaScript(sessionJavascript as String) { (result, error) in
            if error == nil {}
            else{}
        }
        
        let sdkVersion = "iOS_\(Version.number)"
        let BTTVersionValues = String(format: "{\"value\":\"%@\", \"expires\":\"%@\"}", sdkVersion, expiration)
        let versionJavascript = String(format: "localStorage.setItem(\"%@\", JSON.stringify(%@))", "BTT_SDK_VER", BTTVersionValues)
        webView.evaluateJavaScript(sessionJavascript as String) { (result, error) in
            if error == nil {}
            else{}
        }
    }
}

