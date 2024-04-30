# Blue Triangle SDK for iOS

Blue Triangle analytics SDK for iOS.

## Installation

### Installation using Swift Packages Manager

To integrate BlueTriangle using Swift Packages Manager into your iOS project, you need to follow these steps:

 Go to **File > Add Packages…**, enter the package repository URL `https://github.com/blue-triangle-tech/btt-swift-sdk.git`, and click **Add Package**.

 Xcode 11 - 12: go to **File > Swift Packages > Add Package Dependency…** and enter the package repository URL `https://github.com/blue-triangle-tech/btt-swift-sdk.git`, then follow the instructions.

### Installation using CocoaPods

To integrate BlueTriangle using CocoaPods into your iOS project, you need to follow these steps:
  
   1. Open 'Podfile' in text mode and add following:
  
   ```
      pod 'BlueTriangleSDK-Swift'     
  ```

   2. Save the Podfile and run the following command in the terminal to install the dependencies:
    
   ```
      pod install     
  ```


### Configuration

In order to use `BlueTriangle`, you need to first configure `BlueTriangle` SDK. To configure it import `BlueTriangle` and call configure function with your siteID. It is recommended to do this in your `AppDelegate.application(_:didFinishLaunchingWithOptions:)` OR `SceneDelegate.scene(_ scene:, willConnectTo session:, options,connectionOptions:)` method:

```swift
BlueTriangle.configure { config in
    config.siteID = "<MY_SITE_ID>"
}
```

If you are using SwiftUI, it is recommended to add an init() constructor in your App struct and add configuration code there as shown below. 

```swift
import BlueTriangle
import SwiftUI

struct YourApp: App {
    init() {
          
          //Configure BlueTriagle with your siteID
          BlueTriangle.configure { config in
               config.siteID = "<MY_SITE_ID>"
           }
           
           //...
           
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Replace `<BTT_SITE_ID>` with your **site ID**. You can find instructions on how to find your **site ID** [**here**](https://help.bluetriangle.com/hc/en-us/articles/28809592302483-How-to-find-your-Site-ID-for-the-BTT-SDK).

## Timers

To measure the duration of a user interaction, initialize a `Page` object describing that interaction and pass it to `BlueTriangle.startTimer(page:timerType)` to receive a running timer instance.

```swift
let page = Page(pageName: "MY_PAGE")
let timer = BlueTriangle.startTimer(page: page)
```

If you need to defer the start of the timer, pass your `Page` instance to `BlueTriangle.makeTimer(page:timerType)` and call the timer's `start()` method when you are ready to start timing:

```swift
let page = Page(pageName: "MY_PAGE")
let timer = BlueTriangle.makeTimer(page: page)
...
timer.start()
```

In both cases, pass your timer to `BlueTriangle.endTimer(_:purchaseConfirmation:)` to send it to the Blue Triangle server.

```swift
BlueTriangle.endTimer(timer)
```

Running timers are automatically stopped when passed to `BlueTriangle.endTimer(_:purchaseConfirmation:)`, though you can end timing earlier by calling the timer's `end()` method.

```swift
timer.end()
...
// You must still pass the timer to `BlueTriangle.endTimer(_:)` to send it to the Blue Triangle server
BlueTriangle.endTimer(timer)
```

For timers that are associated with checkout, create a `PurchaseConfirmation` object to pass along with the timer to `BlueTriangle.endTimer(_:purchaseConfirmation:)`:

```swift
timer.end()
let purchaseConfirmation = PurchaseConfirmation(cartValue: 99.00)
BlueTriangle.endTimer(timer, purchaseConfirmation: purchaseConfirmation)
```

### Timer Types

`BlueTriangle.makeTimer(page:timerType:)` and `BlueTriangle.startTimer(page:timerType:)` have a `timerType` parameter to specify the type of the timer they return. By default, both methods return main timers with the type `BTTimer.TimerType.main`. When network capture is enabled, requests made with one of the `bt`-prefixed `URLSession` methods will be associated with the last main timer to have been started at the time the request completes. It is recommended to only have a single main timer running at any given time. If you need overlapping timers, create additional custom timers by specifying a `BTTimer.TimerType.custom` timer type:

```swift
let mainTimer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
let customTimer = BlueTriangle.startTimer(page: Page(pageName: "MY_OTHER_TIMER"), timerType: .custom)
// ...
BlueTriangle.endTimer(mainTimer)
// ...
BlueTriangle.endTimer(customTimer)
```

## Network Capture

The Blue Triangle SDK supports capturing network requests using either the `NetworkCaptureSessionDelegate` or `bt`-prefixed `URLSession` methods.

Network requests using a `URLSession` with a `NetworkCaptureSessionDelegate` or made with one of the `bt`-prefixed `URLSession` methods will be associated with the last main timer to have been started at the time a request completes. Note that requests are only captured after at least one main timer has been started and they are not associated with a timer until the request ends.

### `NetworkCaptureSessionDelegate`

You can use `NetworkCaptureSessionDelegate` or a subclass as your `URLSession` delegate to gather information about network requests when network capture is enabled:

```swift
let sesssion = URLSession(
    configuration: .default,
    delegate: NetworkCaptureSessionDelegate(),
    delegateQueue: nil)

let timer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
...
let (data, response) = try await session.data(from: URL(string: "https://example.com")!)
```

if you have already implemented and set URLSessionDelegate to URLSession. You can call  NetworkCaptureSessionDelegate objects urlSession(session: task: didFinishCollecting:) method like bellow.

```swift
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
     
     //Your code ...
     
    let sessionDelegate = NetworkCaptureSessionDelegate()
    sessionDelegate.urlSession(session, task: task, didFinishCollecting: metrics)
}
```

### `URLSession` Methods

Alternatively, use `bt`-prefixed `URLSession` methods to capture network requests:

| Standard                                       | Network Capture                                  |
| :--                                            | :--                                              |
| `URLSession.dataTask(with:completionHandler:)` | `URLSession.btDataTask(with:completionHandler:)` |
| `URLSession.data(for:delegate:)`               | `URLSession.btData(for:delegate:)`               |
| `URLSession.dataTaskPublisher(for:)`           | `URLSession.btDataTaskPublisher(for:)`           |

Use these methods just as you would their standard counterparts:

```swift
let timer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
...
URLSession.shared.btDataTask(with: URL(string: "https://example.com")!) { data, response, error in
    // ...
}.resume()
```

### Mannual Network Capture

For other network capture requirements, captured requests can be manually created and submitted to the tracker.

#### If you have the URL, method, and requestBodyLength in the request, and httpStatusCode, responseBodyLength, and contentType in the response 

```swift
let tracker = NetworkCaptureTracker.init(url: "https://example.com", method: "post", requestBodylength: 9130)
tracker.submit(200, responseBodyLength: 11120, contentType: "json")
```

#### If you have urlRequest in request and urlResponse in response

```swift
        let tracker = NetworkCaptureTracker.init(request: urlRequest)
        tracker.submit(urlResponse) 
```
where urlRequest and urlResponse are of URLRequest and URLResponse types, respectively

#### If you encounters an error during a network call

```swift
        let tracker = NetworkCaptureTracker.init(url: "https://example.com", method: "post", requestBodylength: 9130)
        tracker.failled(error)
        
        OR 
        
        let tracker = NetworkCaptureTracker.init(request: urlRequest)
        tracker.failled(error) 

```

### Network Capture Sample Rate

Network sample rate indicate how many percent session  network request are captured. For exampme a value of `0.05` means that network capture will be randomly enabled for 5% of user sessions. Network sample rate value should be between 0.0 to 1.0 representing fraction value of percent 0 to 100.

The default networkSampleRate value is 0.05, i.e  only 5% of sessions network request are captured.

To change network capture sample rate set value to 'config.networkSampleRate' during configuration like bellow code sets sample rate to 50%.

```swift
BlueTriangle.configure { config in
    config.siteID = "<MY_SITE_ID>"
    config.networkSampleRate = 0.5
    ...
}
```

To dissable network capture set 0.0 to 'config.networkSampleRate' during configuration.

It is recomended to have 100% sample rate while developing/debuging. By setting 'config.networkSampleRate' to 1.0 during configuration.

## Screen View Tracking

All UIKit UIViewControllers view count tracked automatically. You can see each view controller name with there count on our dashboard.

SwiftUI views are not captured automatically. You need to call bttTrackScreen(<screen Name>) modifier on each view which you want to track. Below example show usage of "bttTrackScreen(_ screenName: String)" to track About Us screen.

```swift
struct ContentView: View {
    var body: some View {
        VStack{
            Text("Hello, world!")
        }
        .bttTrackScreen("Demo_Screen")
    }
}
```

To dissable screen tracking, You need to set the enableScreenTracking configuration to false like bellow, This will ignore UIViewControllers activities and bttTrackScreen() modifier calls.

```swift
 BlueTriangle.configure { config in
         ...
         config.enableScreenTracking = false
     }
```

## ANR Detection

BlueTriangle tracks Apps repulsiveness by monitoring main THREAD USAGE. If any task blocking main thread for extended period of time causing app not responding, will be tracked as ANR Morning. By default this time interval is 5 Sec I.e. if any task blocking main thread more then 5 sec will be triggered as ANRWorning. This timinterval can be changed using "ANRWarningTimeInterval" Property below.  

 ```swift
 BlueTriangle.configure { config in
         ...
        config.ANRWarningTimeInterval = 3
     }
```

 To dissable ANR reporting, You need to set "ANRMonitoring" configuration property to "false".
 
 ```swift
 BlueTriangle.configure { config in
         ...
         config.ANRMonitoring = false
     }
```

### Memory Warning

Track ios reported low memory warning. Using UIApplication.didReceiveMemoryWarningNotification Notification.

To disable Memory Warning, You need to set setting "enableMemoryWarning" configuration property to "false".
 
 ```swift
 BlueTriangle.configure { config in
         ...
         config.enableMemoryWarning = false
     }
```

## Network State Capture

 BlueTriangle SDK allows capturing of network state data. Network state refers to the availability of any network interfaces on the device. Network interfaces include wifi, ethernet, cellular, etc. Once Network state capturing is enabled, the Network state is associated with all Timers, Errors and Network Requests captured by the SDK. This feature is enabled by default.

To disable Network state capture, use the enableTrackingNetworkState property on the configuration object as follows

```swift
 BlueTriangle.configure { config in
         ...
         config.enableTrackingNetworkState = false
     }
```


## Offline Caching

Offline caching is a feature that allows the BTT sdk to keep track of timers and other analytics data while the app is
in offline mode. i.e, the BTT sdk cannot access the tracker urls.

There is a memory limit as well as an expiration duration put on the cached data. If the cache exceeds the memory limit
then additional tracker data will be added only after removing some old cached data. Similarly, cache data that has been
stored for longer than the expiration duration would be discarded and won't be sent to the tracker server.

Memory limit and Expiry Duration can be set by using configuration property cacheMemoryLimit and cacheExpiryDuration as shown bellow:``
    
```swift
 BlueTriangle.configure { config in
         ...
            config.cacheMemoryLimit = 50 * 1024 (Bytes)
            config.cacheExpiryDuration = 50 * 60 * 1000 (Milisecond)
     }
```

By default, the cacheMemoryLimit is set to 2 days and cacheExpiryDuration is set to 30 MB.


## WebView Tracking

Websites shown in webview  that are tracked by BlueTriangle can be tracked in the same session as the native app. To achieve this, follow the steps below to configure the WebView:

1. Import BlueTriangle in the hosting iOS WebView class:

  ```swift
      import BlueTriangle
  ```

2. Conform to the WKNavigationDelegate protocol and implement the 'webView(_:didCommit:)' method as follows. 

  ```swift
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        BTTWebViewTracker.webView(webView, didCommit: navigation)
    }
  ``` 


 or if you already have a WKNavigationDelegate porotool, just call the 'BTTWebViewTracker.webView(webView, didCommit: navigation)' in it's 'webView(_:didCommit:)' method.

Here is Swift and SwiftUI implementation example code respectively.

### Swift example code

  ```swift
  
import UIKit
import WebKit
import BlueTriangle

class YourWebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        if let htmlURL = URL(string: "https://example.com"){
            webView.load(URLRequest(url: htmlURL))
        }
    }
}

extension YourWebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        //...
        BTTWebViewTracker.webView(webView, didCommit: navigation)
    }
}

  ``` 

### SwiftUI example code

  ```swift
  
import SwiftUI
import WebKit
import BlueTriangle

struct YourWebView: UIViewRepresentable {
   
    private let webView = WKWebView()
    
    func makeCoordinator() -> YourWebView.Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> some UIView {
        if let htmlURL = URL(string: "https://example.com"){
            webView.navigationDelegate = context.coordinator
            webView.load(URLRequest(url: htmlURL))
        }
        return webView
    }
}

extension YourWebView {
    
    class Coordinator: NSObject, WKNavigationDelegate {
       
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            //...
            BTTWebViewTracker.webView(webView, didCommit: navigation)
        }
    }
}
  ``` 
