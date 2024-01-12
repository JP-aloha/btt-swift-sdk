//
//  BttHybridSupport.swift
//  
//
//  Created by Ashok Singh on 10/01/24.
//

#if canImport(WebKit)
import WebKit
#endif

public class BTTWebViewTracker {
 
    public init(){}
    
    @available(iOS 14.0, macOS 11.0, *)
    public func webView( _ webView: WKWebView, didCommit navigation: WKNavigation!){
        //Session
        let sessionId = "\(BlueTriangle.sessionID)"
        let expiration = NSString(string:"\(Date.addCurrentTimeInMinut(1800))")
        let BTTSessionValues = String(format: "{\"value\":\"%@\", \"expires\":\"%@\"}", sessionId, expiration)
        let sessionJavascript = String(format: "localStorage.setItem(\"%@\", JSON.stringify(%@))", "BTT_X0siD", BTTSessionValues)
        

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        webView.evaluateJavaScript(sessionJavascript as String) { (result, error) in
            if error == nil {}
            else{}
        }
        
        //Version
        let sdkVersion = "iOS_\(Version.number)"
        let BTTVersionValues = String(format: "{\"value\":\"%@\", \"expires\":\"%@\"}", sdkVersion, expiration)
        let versionJavascript = String(format: "localStorage.setItem(\"%@\", JSON.stringify(%@))", "BTT_SDK_VER", BTTVersionValues)
        
        webView.evaluateJavaScript(versionJavascript as String) { (result, error) in
            if error == nil {}
            else{}
        }
    }
}

