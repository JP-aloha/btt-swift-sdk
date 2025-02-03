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
    private var webViews: [WeakWebView] = []
    private static let tracker = BTTWebViewTracker()
  
    public static func webView( _ webView: WKWebView, didCommit navigation: WKNavigation!){
        
        guard BlueTriangle.enableAllTracking else{
            return
        }
        
        let weakWebView = WeakWebView(webView)
        tracker.webViews.append(weakWebView)
        tracker.injectSessionIdOnWebView(webView)
        tracker.injectWCDCollectionOnWebView(webView)
        tracker.injectVersionOnWebView(webView)
    }
    
    public static func updateSessionId(_ sessionID : Identifier){
       
        guard BlueTriangle.enableAllTracking else{
            return
        }
        
        tracker.cleanUpWebViews()
        for web in tracker.webViews {
            if let webView = web.weekWebView{
                self.restitchWebView(webView, sessionID: sessionID)
            }
        }
    }

    public static func verifySessionStitchingOnWebView( _ webView: WKWebView, completion: @escaping (String?, Error?) -> Void){
        
        guard BlueTriangle.enableAllTracking else{
            return
        }
        
#if DEBUG
        let sessionId = "\(BlueTriangle.sessionID)"
        let siteId = "\(BlueTriangle.siteID)"
        
        let bttJSVerificationTag = "_bttTagInit"
        let bttJSSiteIdTag = "_bttUtil.prefix"
        let bttJSSessionIdTag = "_bttUtil.sessionID"
        
        webView.evaluateJavaScript(bttJSVerificationTag) { (result, error) in
            
            if let isBttJSAvailable = result as? Bool{
                
                if isBttJSAvailable {
                    
                    webView.evaluateJavaScript(bttJSSiteIdTag) { (result, error) in
                        
                        if let bttSiteID = result as? String{
                            
                            if bttSiteID == siteId {
                                
                                webView.evaluateJavaScript(bttJSSessionIdTag) { (result, error) in
                                    
                                    if let bttSessionID = result as? String{
                                        
                                        if bttSessionID == sessionId {
                                            BTTWebViewTracker.logger?.info("BlueTriangle: Session stitching was successfull with session \(sessionId) and siteId : \(siteId)")
                                            completion(sessionId, nil)
                                        }else{
                                            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Session stitching has NOT been done. Make sure the BTTWebViewTracker.webView(_:didCommit:) method is invoked from the webview's webView(_:didCommit:) delegate. as explaned in ReadMe. Found app sessionId \(sessionId) and btt.js \(bttSessionID)"])
                                            BTTWebViewTracker.logger?.info("BlueTriangle: \(error.localizedDescription) \(sessionId)")
                                            completion(nil, error)
                                        }
                                    }else{
                                        let error =  NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Something went wrong with btt.js. : \(bttJSSessionIdTag) got \(result ?? "") expected to have tag prifix as String"])
                                        BTTWebViewTracker.logger?.info("BlueTriangle: \(error.localizedDescription) \(sessionId)")
                                        completion(nil, error)
                                    }
                                }
                                
                            }else{
                                let error =  NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Tag url mismatched. This webpage is using different tag url than app siteId. Tag url/btt.js url's tag prefix should be same as app siteId. Found app siteId \(siteId) tag prefix \(bttSiteID)"])
                                BTTWebViewTracker.logger?.info("BlueTriangle: \(error.localizedDescription) \(sessionId)")
                                completion(nil, error)
                            }
                            
                        }else{
                            let error =  NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Something went wrong with btt.js. : \(bttJSSiteIdTag) got \(result ?? "") expected to have tag prifix as String"])
                            BTTWebViewTracker.logger?.info("BlueTriangle: \(error.localizedDescription) \(sessionId)")
                            completion(nil, error)
                        }
                    }
                }else{
                    let error =  NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Something went wrong with btt.js. : \(bttJSVerificationTag) got \(result ?? "") expected to have true"])
                    BTTWebViewTracker.logger?.info("BlueTriangle: \(error.localizedDescription) \(sessionId)")
                    completion(nil, error)
                }
            }else{
                let stitchingError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "btt.js is missing. btt.js not loaded. Make sure btt.js is there in this webpage and its loaded: \(bttJSVerificationTag) got error \(error?.localizedDescription ?? "")"])
                BTTWebViewTracker.logger?.info("BlueTriangle: \(stitchingError.localizedDescription) \(sessionId)")
                completion(nil, stitchingError)
            }
        }
#else
        completion(nil, nil)
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
                BTTWebViewTracker.logger?.error("BlueTriangle: Error while injecting session \(sessionId) : \(error)")
            }
            else{
                BTTWebViewTracker.logger?.info("BlueTriangle: Successfully injected sessionId in WebView: BTT_SDK_VER: \(sessionId) with expiration \(expiration)")
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
                BTTWebViewTracker.logger?.error("BlueTriangle: Error while injecting version for the session  \(sessionId) : \(error)")
            }
            else{
                BTTWebViewTracker.logger?.info("BlueTriangle: Successfully Injected SDK version in WebView: BTT_SDK_VER: \(sdkVersion) with expiration \(expiration) for session \(sessionId)")
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
                    BTTWebViewTracker.logger?.error("BlueTriangle: Error while injecting WCDValues for the session \(sessionId) : \(error)")
                }
                else{
                    BTTWebViewTracker.logger?.info("BlueTriangle: Successfully injected WCDValues for the session \(sessionId)")
                }
            }
        }
    }
    
    private static func hasBttTag(_ web: WKWebView, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            var hasTag = false
            let bttJSVerificationTag = "_bttTagInit"
            let bttJSSiteIdTag = "_bttUtil.prefix"
            let siteId = "\(BlueTriangle.siteID)"
            
            web.evaluateJavaScript(bttJSVerificationTag) { (result, error) in
                if let isBttJSAvailable = result as? Bool, isBttJSAvailable {
                    web.evaluateJavaScript(bttJSSiteIdTag) { (result, error) in
                        if let bttSiteID = result as? String, bttSiteID == siteId {
                            hasTag = true
                        }
                        completion(hasTag)
                    }
                } else {
                    completion(hasTag)
                }
            }
        }
    }
    
    private static func restitchWebView(_ webView : WKWebView, sessionID : Identifier) {
        self.hasBttTag(webView) { hasBtt in
            if (hasBtt) {
                let sessionId = "\(sessionID)"
                tracker.injectSessionIdOnWebView(webView)
                tracker.injectWCDCollectionOnWebView(webView)
                tracker.injectVersionOnWebView(webView)
                BTTWebViewTracker.logger?.info("BlueTriangle: Session re-stitching was successfull with session \(sessionId)")
            }
        }
    }
    
    private func cleanUpWebViews(){
        webViews = webViews.filter { $0.weekWebView != nil }
    }
}

class WeakWebView {
    private(set) weak var weekWebView: WKWebView?
    
    init(_ webView: WKWebView) {
        self.weekWebView = webView
    }
}

#endif
