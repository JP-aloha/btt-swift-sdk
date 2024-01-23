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
     
    static var isEnableScreenTracking = false
    
    public static func webView( _ webView: WKWebView, didCommit navigation: WKNavigation!){
       
        let tracker = BTTWebViewTracker()
        
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        tracker.injectSessionIdOnWebView(webView)
        tracker.injectWCDCollectionOnWebView(webView)
        tracker.injectVersionOnWebView(webView)
    }
    
    private func injectSessionIdOnWebView(_ webView : WKWebView){
       
        //Session
        let sessionId = "\(BlueTriangle.sessionID)"
        let expiration = NSString(string:"\(Date.addCurrentTimeInMinut(18000))")
        let BTTSessionValues = String(format: "{\"value\":\"%@\", \"expires\":\"%@\"}", sessionId, expiration)
        let sessionJavascript = String(format: "localStorage.setItem(\"%@\", JSON.stringify(%@))", "BTT_X0siD", BTTSessionValues)
        
        webView.evaluateJavaScript(sessionJavascript as String) { (result, error) in
            if error == nil {}
            else{}
        }
    }
    
    private func injectVersionOnWebView(_ webView : WKWebView){
        
        //Version
        let sdkVersion = "iOS-\(Version.number)"
        let expiration = NSString(string:"\(Date.addCurrentTimeInMinut(18000))")
        let BTTVersionValues = String(format: "{\"value\":\"%@\", \"expires\":\"%@\"}", sdkVersion, expiration)
        let versionJavascript = String(format: "localStorage.setItem(\"%@\", JSON.stringify(%@))", "BTT_SDK_VER", BTTVersionValues)
        
        webView.evaluateJavaScript(versionJavascript as String) { (result, error) in
            if error == nil {}
            else{}
        }
    }
    
    private func injectWCDCollectionOnWebView(_ webView : WKWebView){
      
        
        if BTTWebViewTracker.isEnableScreenTracking {
            //WCD
            let isEnableTracking = "on"
            let expiration = NSString(string:"\(Date.addCurrentTimeInMinut(18000))")
            let BTTWCDValues = String(format: "{\"value\":\"%@\", \"expires\":\"%@\"}", isEnableTracking, expiration)
            let wcdJavascript = String(format: "localStorage.setItem(\"%@\", JSON.stringify(%@))", "BTT_WCD_Collect", BTTWCDValues)
            
            webView.evaluateJavaScript(wcdJavascript as String) { (result, error) in
                if error == nil {}
                else{}
            }
        }
    }
}



