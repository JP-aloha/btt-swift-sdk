//
//  BttHybridSupport.swift
//  
//
//  Created by Ashok Singh on 10/01/24.
//

#if os(iOS)
import WebKit

public class BTTWebViewTracker {
     
    static var shouldCaptureRequests = false
    static var logger : Logging?
  
    public static func webView( _ webView: WKWebView, didCommit navigation: WKNavigation!){
       
        let tracker = BTTWebViewTracker()
        tracker.injectSessionIdOnWebView(webView)
        tracker.injectWCDCollectionOnWebView(webView)
        tracker.injectVersionOnWebView(webView)
    }

    public static func verifySessionStitchingOnWebView( _ webView: WKWebView, completion: @escaping (Bool, Error?) -> Void){

#if DEBUG
        let sessionId = "\(BlueTriangle.sessionID)"
        let bttJSVerificationTag = "_bttTagInit"
        let bttJSSessionIdTag = "_bttUtil.sessionID"
        
        webView.evaluateJavaScript(bttJSVerificationTag) { (result, error) in
            
            if let isBttJSAvailable = result as? Bool{
               
                if isBttJSAvailable {
                    
                    webView.evaluateJavaScript(bttJSSessionIdTag) { (result, error) in
                        
                        if let bttSessionID = result as? String{
                            
                            if bttSessionID == sessionId {
                                BTTWebViewTracker.logger?.info("BlueTriangle: WebViewTracker: Session stitching was successfully completed for session \(sessionId)")
                                completion(true, nil)
                            }else{
                                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Session stitching has not been done properly. Make sure the BTTWebViewTracker.webView(_:didCommit:) method is invoked from the webview's webView(_:didCommit:) delegate."])
                                BTTWebViewTracker.logger?.info("BlueTriangle: WebViewTracker: \(error.localizedDescription) \(sessionId)")
                                completion(false, error)
                            }
                        }else{
                            let error =  NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Session stitching has not been done properly. Make sure the BTTWebViewTracker.webView(_:didCommit:) method is invoked from the webview's webView(_:didCommit:) delegate."])
                            BTTWebViewTracker.logger?.info("BlueTriangle: WebViewTracker: \(error.localizedDescription) \(sessionId)")
                            completion(false, error)
                        }
                    }
                }else{
                    let error =  NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Unable to load btt.js. Make sure that there are no network issues preventing access."])
                    BTTWebViewTracker.logger?.info("BlueTriangle: WebViewTracker: \(error.localizedDescription) \(sessionId)")
                    completion(false, error)
                }
            }else{
                let stitchingError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Unable to load btt.js. Make sure that there are no network issues preventing access : \(error?.localizedDescription ?? "")"])
                BTTWebViewTracker.logger?.info("BlueTriangle: WebViewTracker: \(stitchingError.localizedDescription) \(sessionId)")
                completion(false, stitchingError)
            }
        }
#endif
        
    }
}

extension BTTWebViewTracker {
    
    private func injectSessionIdOnWebView(_ webView : WKWebView){
       
        //Session
        let sessionId = "\(BlueTriangle.sessionID)"
        let expiration = NSString(string:"\(Date.addCurrentTimeInMinut(18000))")
        let BTTSessionValues = String(format: "{\"value\":\"%@\", \"expires\":\"%@\"}", sessionId, expiration)
        let sessionJavascript = String(format: "localStorage.setItem(\"%@\", JSON.stringify(%@))", "BTT_X0siD", BTTSessionValues)
        
        webView.evaluateJavaScript(sessionJavascript as String) { (result, error) in
            
            if let error =  error {
                BTTWebViewTracker.logger?.error("BlueTriangle: WebViewTracker: Error while injecting session \(sessionId) : \(error)")
            }
            else{
                BTTWebViewTracker.logger?.info("BlueTriangle: WebViewTracker: Successfully injected session \(sessionId)")
            }

        }
    }
    
    private func injectVersionOnWebView(_ webView : WKWebView){
        
        //Version
        let sdkVersion = "iOS-\(Version.number)"
        let sessionId = "\(BlueTriangle.sessionID)"
        let expiration = NSString(string:"\(Date.addCurrentTimeInMinut(18000))")
        let BTTVersionValues = String(format: "{\"value\":\"%@\", \"expires\":\"%@\"}", sdkVersion, expiration)
        let versionJavascript = String(format: "localStorage.setItem(\"%@\", JSON.stringify(%@))", "BTT_SDK_VER", BTTVersionValues)
        
        webView.evaluateJavaScript(versionJavascript as String) { (result, error) in
            if let error =  error {
                BTTWebViewTracker.logger?.error("BlueTriangle: WebViewTracker: Error while injecting version for the session  \(sessionId) : \(error)")
            }
            else{
                BTTWebViewTracker.logger?.info("BlueTriangle: WebViewTracker: Successfully injected version for the session \(sessionId)")
            }
        }
    }
    
    private func injectWCDCollectionOnWebView(_ webView : WKWebView){
      
        
        if BTTWebViewTracker.shouldCaptureRequests {
            //WCD
            let isEnableTracking = "on"
            let sessionId = "\(BlueTriangle.sessionID)"
            let expiration = NSString(string:"\(Date.addCurrentTimeInMinut(18000))")
            let BTTWCDValues = String(format: "{\"value\":\"%@\", \"expires\":\"%@\"}", isEnableTracking, expiration)
            let wcdJavascript = String(format: "localStorage.setItem(\"%@\", JSON.stringify(%@))", "BTT_WCD_Collect", BTTWCDValues)
            
            webView.evaluateJavaScript(wcdJavascript as String) { (result, error) in
                if let error =  error {
                    BTTWebViewTracker.logger?.error("BlueTriangle: WebViewTracker: Error while injecting WCDValues for the session \(sessionId) : \(error)")
                }
                else{
                    BTTWebViewTracker.logger?.info("BlueTriangle: WebViewTracker: Successfully injected WCDValues for the session \(sessionId)")
                }
            }
        }
    }
}

#endif
