# Blue Triangle SDK for iOS

Blue Triangle analytics SDK for iOS.

## Installation

### Installation using Swift Packages Manager

To integrate BlueTriangle using Swift Packages Manager into your iOS project, you need to follow these steps:

 Go to **File > Add Packages…**, enter the package repository URL `https://github.com/blue-triangle-tech/btt-swift-sdk.git`, and click **Add Package**.

 Xcode 11 - 12: go to **File > Swift Packages > Add Package Dependency…** and enter the package repository URL `https://github.com/blue-triangle-tech/btt-swift-sdk.git`, then follow the instructions.

### Installation using CocoaPods

To integrate BlueTriangle using CocoaPods into your iOS project, you need to follow these steps:
  
   1. Open 'Podfile' in text mode and specify following commands:
  
   ```
      pod 'BlueTriangleSDK-Swift'     
  ```

   2. Save the Podfile and run the following command in the terminal to install the dependencies:
    
   ```
      pod install     
  ```


## Usage

### Configuration

Before sending timers you must first configure `BlueTriangle`. It is recommended to do this in your `AppDelegate.application(_:didFinishLaunchingWithOptions:)` method:

```swift
BlueTriangle.configure { config in
    config.siteID = "MY_SITE_ID"
    config.isReturningVisitor = true
    config.abTestID = "MY_AB_TEST_ID"
    config.campaignMedium = "MY_CAMPAIGN_MEDIUM"
    config.campaignName = "MY_CAMPAIGN_NAME"
    config.campaignSource = "MY_CAMPAIGN_SOURCE"
    config.dataCenter = "MY_DATA_CENTER"
    config.trafficSegmentName = "MY_SEGMENT_NAME"
    config.crashTracking = .nsException
    config.performanceMonitorSampleRate = 1.0
}
```
Replace MY_SITE_ID with your site id. You can find your site ID on the website by following below steps:

1.Go to [https://portal.bluetriangletech.coml](https://portal.bluetriangletech.com)
2.Login with your portal Account
3.Go to Settings & Administration.
4.Click on Site Configuration.
5.Select Sites.
6.Get the site id for you site as shown in image below

![Image]{./SettingsSites.jpeg}

### Timers

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

#### Timer Types

`BlueTriangle.makeTimer(page:timerType:)` and `BlueTriangle.startTimer(page:timerType:)` have a `timerType` parameter to specify the type of the timer they return. By default, both methods return main timers with the type `BTTimer.TimerType.main`. When network capture is enabled, requests made with one of the `bt`-prefixed `URLSession` methods will be associated with the last main timer to have been started at the time the request completes. It is recommended to only have a single main timer running at any given time. If you need overlapping timers, create additional custom timers by specifying a `BTTimer.TimerType.custom` timer type:

```swift
let mainTimer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
let customTimer = BlueTriangle.startTimer(page: Page(pageName: "MY_OTHER_TIMER"), timerType: .custom)
// ...
BlueTriangle.endTimer(mainTimer)
// ...
BlueTriangle.endTimer(customTimer)
```

### Network Capture

The Blue Triangle SDK supports capturing network requests using either the `NetworkCaptureSessionDelegate` or `bt`-prefixed `URLSession` methods.

To enable network capture, first configure the SDK with a non-zero network sample rate:

```swift
BlueTriangle.configure { config in
    ...
    config.networkSampleRate = 0.05
}
```

A value of `0.05`, for example, means that network capture will be randomly enabled for 5% of user sessions. Network requests using a `URLSession` with a `NetworkCaptureSessionDelegate` or made with one of the `bt`-prefixed `URLSession` methods will be associated with the last main timer to have been started at the time a request completes. Note that requests are only captured after at least one main timer has been started and they are not associated with a timer until the request ends.

#### `NetworkCaptureSessionDelegate`

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

#### `URLSession` Methods

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

```swift
let tracker = NetworkCaptureTracker.init(url: "https://hub.dummyapis.com/delay?seconds=3", method: "post", requestBodylength: 9130)
tracker.submit(200, responseBodyLength: 11120, contentType: "json")
```


### Screen View Tracking

All UIViewControllers view count can be tracked. Setting "enableScreenTracking"  configuration property to true will capture view counts of every UIViewController in your app. You can see each view controller name with there count on our dashboard.

```swift
 BlueTriangle.configure { config in
         ...
         config.enableScreenTracking = true
     }
```

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

### ANR Detection

ANR(Application Not Responding) detects to main thread in which an app becomes unresponsive or stops responding to user input for an extended period of time. It can be enabled by setting "ANRMonitoring" configuration property to "true". And it can set Interval, to consider it an ANR situation by setting "ANRWarningTimeInterval" configuration property as shown below.


```swift
 BlueTriangle.configure { config in
         ...
         config.ANRMonitoring = true
         config.ANRWarningTimeInterval = 3
     }
```
By default, the ANR interval is set to 5 seconds.


### Memory Warning

Track ios reported low memory worning. iOS reported meory wornings can be tracked by btt. It can be enabled by setting "enableMemoryWarning" configuration property to "true".


```swift
 BlueTriangle.configure { config in
         ...
         config.enableMemoryWarning = true
     }
```


### Network State Capture

 BlueTriangle SDK allows capturing of network state data. Network state refers to the availability of any network interfaces on the device. Network interfaces include wifi, ethernet, cellular, etc. Once Network state capturing is enabled, the Network state is associated with all Timers, Errors and Network Requests captured by the SDK.

To enable Network state capture, use the enableTrackingNetworkState property on the configuration object as follows


```swift
 BlueTriangle.configure { config in
         ...
         config.enableTrackingNetworkState = true
     }
```



### Offline Caching

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


### WebView Tracking

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

