# Blue Triangle SDK for iOS

The Blue Triangle SDK for iOS enables application owners to track their users’ experience so they can focus on user experience issues that impact their business outcomes.

## Supported metrics
- Performance & Network Timings
 - Main Timers
 - Network Timers
 - Custom Timers
- Errors & Crashes
- Application Not Responding (ANR)
- HTTP Response Codes
- App Crashes
- Device Stats & Session Attributes
 - OS/OS Version
 - App Version
 - Device Type
 - Geographical/Country
 - CPU Usage
 - Memory Warnings
 - Memory/Out of Memory
 - Hot/Cold Launch
Coming Soon
- Network Type
 

## Mandatory Installation Steps

### SDK Installation

#### Installation using Swift Packages Manager

To integrate BlueTriangle using Swift Packages Manager into your iOS project, you need to follow these steps:

 Go to **File > Add Packages…**, enter the package repository URL `https://github.com/blue-triangle-tech/btt-swift-sdk.git`, and click **Add Package**.

 Xcode 11 - 12: go to **File > Swift Packages > Add Package Dependency…** and enter the package repository URL `https://github.com/blue-triangle-tech/btt-swift-sdk.git`, then follow the instructions.

#### Installation using CocoaPods

To integrate BlueTriangle using CocoaPods into your iOS project, you need to follow these steps:
  
   1. Open 'Podfile' in text mode and add following:
  
   ```
      pod 'BlueTriangleSDK-Swift'     
  ```

   2. Save the Podfile and run the following command in the terminal to install the dependencies:
    
   ```
      pod install     
  ```


### Configuration- Mandatory

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

@main
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

### Privacy Manifest Note

**It is the application developers' responsibility to ensure privacy nutrition labels are according to usage of BlueTriangle SDK in your app. For instance if your app uses revenue tracking(Timers cartValue) its app developers responsibility to mention Purchase History in there apps privacy manifest data usage.** For more detail see [privacy manifest chapter](#privacy-manifest)

### Native View Performance Tracking- Mandatory

All UIKit UIViewControllers view counts will be tracked automatically. You can see each view controller name with their count on our dashboard. If you want to ignore a specific view controller (i.e., do not want to track that screen), you can exclude it using the 'ignoreViewControllers' configuration property as follows. 
 
Ensure the view controller name matches exactly, as it is case-sensitive.


```swift
BlueTriangle.configure { config in
         ...
         config.ignoreViewControllers = ["UIViewController"]
 }
```

SwiftUI views are not captured automatically. You need to call bttTrackScreen() modifier on each view which you want to track. Below example show usage of "bttTrackScreen(_ screenName: String)" to track About Us screen.

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

To disable screen tracking, you need to set the enableScreenTracking configuration to false during configuration like bellow, This will ignore UIViewControllers activities and bttTrackScreen() modifier calls.

```swift
BlueTriangle.configure { config in
         ...
         config.enableScreenTracking = false
 }
```

### Native View/WebView Tracking/Session Stitching- Mandatory

Websites shown in webview that are tracked by BlueTriangle can be tracked in the same session as the native app. To achieve this, follow the steps below to configure the WebView:

Implement WKNavigationDelegate protocol and call BTTWebViewTracker.webView(webView, didCommit: navigation) in 'webView(_:didCommit:)' delegate method as follows.


```swift

import BlueTriangle

  //....

 extension YourWebViewController: WKNavigationDelegate{

  //....

  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {

      //....

      //Call BlueTringles 'webView(_:didCommit:)' method
      BTTWebViewTracker.webView(webView, didCommit: navigation)
    }

 }
```

For more clarity, here is a Webview with UIViewController full example:

```swift

import UIKit
import WebKit
//Need to import BlueTriangle
import BlueTriangle

class YourWebViewController: UIViewController {
  @IBOutlet weak var webView: WKWebView!

  override func viewDidLoad() {
      super.viewDidLoad()

      //Set navigationDelegate
      webView.navigationDelegate = self

      //Load Url
      if let htmlURL = URL(string: "https://example.com"){
          webView.load(URLRequest(url: htmlURL))
      }
  }
}

//Implement Navigation Delagate
extension YourWebViewController: WKNavigationDelegate {

  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {

      //...

      //Call BlueTringles 'webView(_:didCommit:)' method
      BTTWebViewTracker.webView(webView, didCommit: navigation)
  }
}

```

Webview with SwiftUI full example:

```swift

import SwiftUI
import WebKit
//Need to import BlueTriangle
import BlueTriangle

struct YourWebView: UIViewRepresentable {

  private let webView = WKWebView()

  func makeCoordinator() -> YourWebView.Coordinator {
      Coordinator()
  }

  func makeUIView(context: Context) -> some UIView {

      //Set navigationDelegate
      webView.navigationDelegate = context.coordinator

      //Load Url
      if let htmlURL = URL(string: "https://example.com"){
          webView.load(URLRequest(url: htmlURL))
      }
      return webView
  }
}

extension YourWebView {

  //Implement Navigation Delegate  Coordinator

  class Coordinator: NSObject, WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {

          //...

          //Call BlueTringles 'webView(_:didCommit:)' method
          BTTWebViewTracker.webView(webView, didCommit: navigation)
      }
  }
}

```
** Troubleshoot session stitching **

To verify if session stitching is done correctly, We have function verifySessionStitchingOnWebView(_:completion:) to verify. Use is for debuging purpose only 

Inside WKNavigationDelegate protocol's webView(_:didFinish:) delegate method, call BTTWebViewTracker.verifySessionStitchingOnWebView(_:completion:) as follows.

```swift

import BlueTriangle

  //....

extension YourWebViewController: WKNavigationDelegate{

  //....

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

  //....

   //Call BlueTringles 'verifySessionStitchingOnWebView(_:completion:)' method
    BTTWebViewTracker.verifySessionStitchingOnWebView(webView) { sessionId, error in
        if let error = error{
            NSLog("BlueTriangle: \(error)")
        }else{
            NSLog("BlueTriangle: Session stitching was successfull for session \(sessionId)")
        }
    }
  }
}
```

### Network Capture- Mandatory

The Blue Triangle SDK supports capturing network requests using either the bt-prefixed URLSession methods or the NetworkCaptureSessionDelegate.

Network requests using a URLSession with a NetworkCaptureSessionDelegate or made with one of the bt-prefixed URLSession methods will be associated with the last main timer to have been started at the time a request completes. Note that requests are only captured after at least one main timer has been started and they are not associated with a timer until the request ends.

#### NetworkCaptureSessionDelegate

You can use NetworkCaptureSessionDelegate or a subclass as your URLSession delegate to gather information about network requests when network capture is enabled:

```swift
let session = URLSession(
    configuration: .default,
    delegate: NetworkCaptureSessionDelegate(),
    delegateQueue: nil)

let timer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
...
let (data, response) = try await session.data(from: URL(string: "https://example.com")!)
```

If you have already implemented and set URLSessionDelegate to URLSession, you can call NetworkCaptureSessionDelegate objects urlSession(session: task: didFinishCollecting:) method:


```swift
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {

     //Your code ...

    let sessionDelegate = NetworkCaptureSessionDelegate()
    sessionDelegate.urlSession(session, task: task, didFinishCollecting: metrics)
}
```

#### URLSession Methods

Alternatively, use bt-prefixed URLSession methods to capture network requests:

| Standard                                     | Network Capture                                |  
|----------------------------------------------|------------------------------------------------|
| URLSession.dataTask(with:completionHandler:) | URLSession.btDataTask(with:completionHandler:) | 
| URLSession.data(for:delegate:)               | URLSession.btData(for:delegate:)               | 
| URLSession.dataTaskPublisher(for:)           | URLSession.btDataTaskPublisher(for:)           | 

Use these methods just as you would their standard counterparts:

```swift

let timer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
...
URLSession.shared.btDataTask(with: URL(string: "https://example.com")!) { data, response, error in
    // ...
}.resume()

```

### Manual Network Capture

For other network capture requirements, captured requests can be manually created and submitted to the tracker.

**If you have the URL, method, and requestBodyLength in the request, and httpStatusCode, responseBodyLength, and contentType in the response**
```swift

let tracker = NetworkCaptureTracker.init(url: "https://example.com", method: "post", requestBodylength: 9130)
tracker.submit(200, responseBodyLength: 11120, contentType: "json")

```

**If you have urlRequest in request and urlResponse in response**

```swift

let tracker = NetworkCaptureTracker.init(request: urlRequest)
tracker.submit(urlResponse)

```
where urlRequest and urlResponse are of URLRequest and URLResponse types, respectively.

**If you encounter an error during a network call**

```swift

let tracker = NetworkCaptureTracker.init(url: "https://example.com", method: "post", requestBodylength: 9130)
tracker.failed(error)

        OR

let tracker = NetworkCaptureTracker.init(request: urlRequest)
tracker.failed(error)

```

## Recommended (Optional) Configurations

### Network Capture Sample Rate

Network sample rate indicates the percentage of session network requests that are captured. For example a value of 0.05 means that network capture will be randomly enabled for 5% of user sessions. Network sample rate value should be between 0.0 to 1.0 representing fraction value of percent 0 to 100. The default networkSampleRate value is 0.05, i.e only 5% of sessions network request are captured.

To change the network capture sample rate set value of the 'config.networkSampleRate' to 0.5 to set is to 50%.

```swift
BlueTriangle.configure { config in
    config.siteID = "<MY_SITE_ID>"
    config.networkSampleRate = 0.5
    ...
}
```

To disable network capture set 0.0 to 'config.networkSampleRate' during configuration.

It is recommended to have 100% sample rate while developing/debugging. By setting 'config.networkSampleRate' to 1.0 during configuration.

### Blue Triangle Campaign Configuration Fields

The following fields can be used to identify and segment users for optimized analytics contextualization. They can be configured in the SDK and modified in the app in real time, and they show in the Blue Triangle portal as parameters for reporting.


| Field                                        | Implication                                                                                                                                                           |  
|----------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| abTestID="MY_AB_TEST_ID"                     | Capture a variable that allows us to understand a live AB test of two variants in the app.                                                                            | 
| campaignMedium="MY_CAMPAIGN_MEDIUM"          | Understand the general reason the journey started (email, paid search, organic search, etc)                                                                           | 
| campaignName="MY_CAMPAIGN_NAME"              | Understand the campaign name that started the journey.                                                                                                                | 
| campaignSource="MY_CAMPAIGN_SOURCE"          | Understanding the type of marketing campaign.                                                                                                                         | 
| dataCenter="MY_DATA_CENTER"                  | Understand if you have multiple data centers that serve your customers you can group data by them.                                                                    | 
| trafficSegmentName="MY_SEGMENT_NAME"         | This can be used to segment environment type.  For instance, we can use this to understand if you have beta vs prod but both are live versions of the app.            | 

```swift
BlueTriangle.setAbTestID("MY_AB_TEST_ID")
BlueTriangle.setCampaignName("MY_CAMPAIGN_NAME")
BlueTriangle.setCampaignMedium("MY_CAMPAIGN_MEDIUM")
BlueTriangle.setCampaignSource("MY_CAMPAIGN_SOURCE")
BlueTriangle.setDataCenter("MY_DATA_CENTER")

BlueTriangle.configure { config in
    config.trafficSegmentName = "MY_TRAFFIC_SEGEMENT_NAME"
}
```


### Custom Timers

While **Screen Views are automatically tracked upon installation**, Custom Timers can also be configured if needed. 
The **automated timers capture** are following these events:

![image](https://github.com/blue-triangle-tech/btt-swift-sdk/assets/147184142/4bcfadc7-c8e5-47ec-a518-e491c51ac11c)


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
### Checkout Event Data
Upon a customer checkout, it is possible to configure the following data parameters for the event.

Brand Value
```swift
let timer = BlueTriangle.startTimer( page: Page( pageName: "SignUp", brandValue: 100.0)) 
BlueTriangle.endTimer(timer)
```

Cart Value, Cart Count, Cart Count Checkout, Order Number

```swift
let timer = BlueTriangle.startTimer( 
    page: Page( 
        pageName: "Confirmation")) 
BlueTriangle.endTimer( 
    timer, 
    purchaseConfirmation: PurchaseConfirmation( 
        cartValue:99.0, 
        cartCount: 2,
        cartCountCheckout : 2,
        orderNumber: "ORD-123345"))
```

Order Time

The PurchaseConfirmation includes an order time, which is automatically set to the end time of the time.

## Optional Configuration Steps

### ANR Detection

BlueTriangle tracks Apps responsiveness by monitoring main THREAD USAGE. If any task blocking main thread for extended period of time causing app not responding, will be tracked as ANR Morning. By default this time interval is 5 Sec I.e. if any task blocking main thread more then 5 sec will be triggered as ANRWorning. This timinterval can be changed using "ANRWarningTimeInterval" Property below.  

 ```swift
 BlueTriangle.configure { config in
         ...
        config.ANRWarningTimeInterval = 3
 }
```

You can disable it by setting "ANRMonitoring" configuration property to "false" during configuration.
 
 ```swift
 BlueTriangle.configure { config in
         ...
         config.ANRMonitoring = false
 }
```

### Memory Warning

Blue Triangle track ios reported low memory warning. By monitoring UIApplication.didReceiveMemoryWarningNotification Notification.

You can disable it by setting "enableMemoryWarning" configuration property to "false" during configuration.
 
 ```swift
 BlueTriangle.configure { config in
         ...
         config.enableMemoryWarning = false
 }
```

### Memory Usage

Memory usage is the amount of memory used by the code during the Timer interval. This is measured in number of bytes.

Against each timer, 3 Memory measurements are being sent, minimum, maximum and average.

Memory usage refers to the amount memory (RAM) that is currently being used by application to store and manage data. In analytics.rcv payload data json, 'minMemory', 'maxMemory' and 'avgMemory' are being used to send the respective memory usage.

To set the interval (in seconds) at which the Memory usage is being captured, set the following field:

 ```swift
 BlueTriangle.configure { config in
         ...
         config.performanceMonitorSampleRate = 1
     }
```

To disable Memory usage set the following field:

 ```swift
BlueTriangle.configure { config in
       ...
       config.isPerformanceMonitorEnabled = false
   }
```

### CPU Usage

CPU Usage is the amount of CPU being used by the code during the Timer interval. This is measured in the form of 0-100%.

Against each timer, 3 CPU measurements are being sent, minimum, maximum and average.

CPU usage is being reported by xcode as X.100% format [where X is number of cores], it typically means that the system is utilizing the CPU resources heavily. To express this in a 0% to 100% format, Blue Triangle calculates the CPU usage by dividing number of CPU cores. This will give you a percentage value between 0% and 100%.

**0% to 100% format = Total current CPU usage on Instruments / Number of CPU cores.**

For example, if you have 4 CPU cores and your current usage is 300%. then actual BTT CPU usage 300% / 4 = 75%. This indicates that CPU is being utilized at 75% of its total capacity.
 

To set the interval (in s) at which the CPU usage is being captured, set the following field in BlueTriangleConfiguration:

```swift
BlueTriangle.configure { config in
         ...
         config.performanceMonitorSampleRate = 1
     }
```

To disable CPU usage set the following field in BlueTriangleConfiguration:

```swift
BlueTriangle.configure { config in
       ...
       config.isPerformanceMonitorEnabled = false
   }
```


### Offline Caching

Offline caching is a feature that allows the BTT SDK to keep track of timers and other analytics data while the app is in offline mode. i.e, the BTT SDK cannot send data back to Blue Triangle.

There is a memory limit as well as an expiration duration put on the cached data. If the cache exceeds the memory limit then additional tracker data will be added only after removing some older, cached data (first in, first out). Similarly, cache data that has been stored for longer than the expiration duration would be discarded and won't be sent to the tracker server.

Memory limit and Expiry Duration can be set by using configuration property cacheMemoryLimit and cacheExpiryDuration as shown below:

```swift

 BlueTriangle.configure { config in
         ...
            config.cacheMemoryLimit = 50 * 1024 (Bytes)
            config.cacheExpiryDuration = 50 * 60 * 1000 (Millisecond)
 }
```

By default, the cacheMemoryLimit is set to 48 hours and cacheExpiryDuration is set to 30 MB.

### Network State Capture

BlueTriangle SDK allows capturing of network state data. Network state refers to the availability of any network interfaces on the device. Network interfaces include wifi, ethernet, cellular, etc. Once Network state capturing is enabled, the Network state is associated with all Timers, Errors and Network Requests captured by the SDK. This feature is enabled by default.

You can disable it by setting enableTrackingNetworkState property to "false" during configuration.

```swift
 BlueTriangle.configure { config in
         ...
         config.enableTrackingNetworkState = false
  }
```

### Launch Time

BlueTriangle tracks app launch performance. Launch time refers to the duration it takes for an app to become ready for user interaction after it has been started. BlueTriangle automatically tracks both hot launch and cold launch.


#### Cold Launch

 A cold launch is launch when app process was already not in main memory. This can happen because iOS or user terminated your apps process or its first time launch after install/update/reboot.

 The BlueTriangle SDK measures the cold launch latency, which is the time between the process start time and end of 'applicationDidBecomeActive(:)'. So that cold launch time is cumulative time taken to load the process and time taken by 'application(:didFinishLaunchingWithOptions:)', 'applicationWillEnterForeground(:)' and 'applicationDidBecomeActive(:)'.
   
#### Hot Launch

  A hot launch is launch when app process was already in main memory. This can happen when user launches the app from the background.
 
  The BlueTriangle SDK measures the hot launch latency, which is the time between the end of 'applicationWillEnterForeground(:)' and end of 'applicationDidBecomeActive(:)'. So that hot launch time taken by 'applicationDidBecomeActive(:)'.

  When user lock the device while app was on screen and unlocks it iOS gives background and forground notification. Hence unclocking followed by lock while app was active is tracked as Hot Launch

You can disable it by setting "enableLaunchTime" configuration property to "false" during configuration. like
 
 ```swift
 BlueTriangle.configure { config in
         ...
         config.enableLaunchTime = false
 }
```

### Crash tracking

Blue triangle tracks app crashes to report crash revenue correlation. By default crash tracking is enabled.

It is recommended to configure blue triangle sdk before any other crash tracking tool to not get conflict with other crash reporting tool. We advise to test your crash reporting before production to make sure crashes are reported to both blue triangle and your other crash tracking tool. Crash tracking tools may conflict each other, not configuring blue triangle sdk before other crash tracking tool may result in conflict which leads bluetriangle is not able to track crashes. Try changing order of configuration and disabling one another.

To disable blue triangle crash tracking use following configuration

```swift

BlueTriangle.configure { config in
    config.siteID = "<MY_SITE_ID>"
    //Disable crash tracking
   config.crashTracking = .none
}
```

If by any reason you cant configure bluetriangle before your crash tracking tool configuration. You can use BlueTriangle.startCrashTracking(), this function allows bluetriangle to start crash tracking before configuring bluetriangle sdk. This helps in scenarios where you want to configure blue triangle sdk later after your another crash tracking tool is configured.


### Custom Variables

It is a developer-defined property introduced into the BTT SDK payload that developers can include to collect and track extra information specific to their application needs.

To introduce a custom variable, the developer first needs to create it on the BlueTriangle portal by following the instructions on the [**Custom Variables Page.**](https://help.bluetriangle.com/hc/en-us/articles/15629245281171-RUM-Custom-Variables-Page)

Then developer need to set custom variable using the below function:

```swift
   BlueTriangle.setCustomVariable(<VARIABLE NAME>, value: <VALUE>)
```

In order to get the custom variable value, call the following with the variable name:

```swift
   let value = BlueTriangle.getCustomVariable(<VARIABLE NAME>)
```

To remove a custom variable value, call the following function with the variable name:

```swift
   BlueTriangle.clearCustomVariable(<VARIABLE NAME>)
```

To remove all custom variable values, call the following function:

```swift
   BlueTriangle.clearAllCustomVariables()
```

where &lt;VARIABLE NAME&gt; is the variable name of the custom variable that the user added to the portal while creating the custom variable e.g. CV1, CV2, etc, and <VALUE> is whatever the developer wants to set in these fields.

Once the value is set, it will be sent with each page view until it is cleared by calling any of the above clear methods.

To view one of the values on the portal, navigate to the path 'Menu > Native App Monitoring > Native App Performance Detail' or go to the Session Lookup Page. Then, search by session ID and see the Performance Measurement Details for the specific page.
[**for more detail**](https://help.bluetriangle.com/hc/en-us/articles/12299711775635-Where-can-I-see-Custom-Variables)

### Custom Categories

Custom Categories are developer-defined filter fields that are attached to screen views. They allow you to filter and break down native screen analytics inside the Blue Triangle portal.

The SDK supports up to five Custom Category fields, which can be set as follows:

```swift
     BlueTriangle.setCustomCategory1("Value_1")
     BlueTriangle.setCustomCategory2("Value_2")
     BlueTriangle.setCustomCategory3("Value_3")
     BlueTriangle.setCustomCategory4("Value_4")
     BlueTriangle.setCustomCategory5("Value_5")
```

Once set, Custom Category values are persisted locally and will be included with every subsequent Screen View event until overridden or cleared by setting null.

Common use cases include Logged-in vs guest users, Feature flag segmentation, Different versions of the same screen flow.

Custom Categories can be used as filters in the Blue Triangle portal after data has been processed.

```
Custom Category currently requires help from a Blue Triangle representative for configuration. Please reach out and they will be able to help you with this!
```

### Grouping 

Blue Triangle connects user experience to business outcomes by instrumenting an SDK in mobile apps to capture key metrics and events. Unlike most SDKs that only collect raw components—Classes (Activities and Fragments), Composables, Blue Triangle automatically groups them into meaningful user steps, enabling clear business impact analysis while still providing detailed data for developer-level optimizations.

Blue Triangle groups ViewControllers and Fragments of a single screen. If two or more ViewControllers or Fragments lifecycle start within two seconds without any user action in between, then those are part of a group.

When this feature is enabled, the SDK automatically groups all single-screen Activities, Fragments or Composables under a group name derived from either:  
1. The screen title, or
2. The class name of the last appearing view.

Developers can also manually update or create group names using the following APIs:

Developer can update current group by using the below function:

```swift
   BlueTriangle.setGroupName(<Group name>)
```

 And, Developer can create new group by using the below function:

```swift
   BlueTriangle.setNewGroup(<Group name>)
```

Visit the [**Official Help Doc**](https://help.bluetriangle.com/hc/en-us/articles/44149857145491-Understanding-the-User-Experience-through-Automated-Step-Grouping-in-Mobile-Applications) for more info.

## How to Test your iOS SDK Integration

### Site ID

Log onto your account on the [Blue Triangle Portal](https://portal.bluetriangle.com), head over to "Native App -> Performance overview" and see that you can observe some data.

### Memory Warning

To test Memory Warning, In the iOS Simulator, you can generate a memory warning using the following steps:

1. Launch Simulator
2. Go to XCode 'Debug' menu
3. Select 'Simulate Memory Warning' to generate memory warning

### ANR Tracking

To test ANR Tracking, You can declare and call the following function on the main thread:

```swift

func testANRTracking(){  let startTime = Date()  while true {  if (Date().timeIntervalSince1970 - startTime.timeIntervalSince1970) > 30 {  break  }  }  }
```

### Crash Tracking

To test Crash Tracking, you can declare and call the following function:

```swift

func testCrashTracking() {  let array = NSArray()  array.object(at: 99)  }

```

### Microsoft Clarity Integration

Blue Triangle offers session playback via Microsoft Clarity integration. For help with this process, please reach out to your Blue Triangle representative.

To get started, integrate and configure Microsoft Clarity as shown in the official [Microsoft Clarity Documentation](https://learn.microsoft.com/en-us/clarity/mobile-sdk/ios-sdk?tabs=swift-package-manager%2Cswift) using your Clarity project ID. 

Blue Triangle automatically detects Clarity in your app and based on that it automatically does the session mapping between Blue Triangle and Microsoft Clarity.


## Troubleshooting

### Optional Launch Arguments for Testing and Debugging


To facilitate testing and debugging, the SDK includes optional launch arguments that allow developers to simulate specific scenarios when running the app from Xcode.

1. Full Sample Rate Mode 

This argument enables the SDK to operate with a 100% network sample rate, which is useful for testing scenarios where all networs are captured and processed.

  ```swift

  -FullSampleRate
 
  ```

2. New Session on Each Launch 

This argument forces a new session to start on each app launch. It is helpful for testing session-based features, ensuring each run begins with a clean session state.

  ```swift

   -NewSessionOnLaunch

  ```


These arguments only apply when the app is launched using the Xcode play button. They do not apply when the app is launched directly on a device by tapping the app icon.

You can add these arguments by editing your project's scheme and adding a new entry to "Arguments Passed On Launch":

1. Open Xcode.
2. Navigate to Edit Scheme > Run > Arguments.
3. Add the desired arguments (-FullSampleRate,  -NewSessionOnLaunch) to Arguments Passed On Launch.




