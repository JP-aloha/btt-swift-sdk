# Blue Triangle 3.14.0, Latest
### New Features
  - Added support for Blutriange and Microsoft clarity session mapping. Added ability to detect clarity sdk present in host app, if present associate clarity session url with timers

# Blue Triangle 3.13.2, Feb 7 2015
### New Features
  - Added ability to disabling or enabling the SDK through the remote configuration system, providing full control over its functionality in real-time. When the SDK is disabled, all features, including data collection, processing, and network operations, are suspended.
### Bug Fixes and Improvements
- Resolved an issue in the CaptureTimerManagerTests where asynchronous handler execution would sometimes occur after the test timeout.

# Blue Triangle 3.13.1, Dec 27 2024
### New Features
- Ability to remotely ignore automatically tracked screen names. Developers can configure a list of page names from the BlueTriangle portal, which will be ignored from tracking. Any view controller class name or page name given in SwiftUI .bttTrackScreen() modifiers will also be ignored. These names are case-sensitive. This feature allows developers to remotely calibrate the list of view controllers or views they want to track at any time.
  
### Bug Fixes and Improvements
- Ignore system-defined view controllers whose bundleIdentifier starts with com.apple
- Fixed an issue where non-ASCII characters in the User-Agent header were not properly encoded, leading to server-side decoding errors. Non-ASCII characters are now replaced with ? to ensure compatibility and prevent errors during processing.

# Blue Triangle 3.13.0, Dec 6 2024
### New Features
-  Ability to remotely overwrite Network Sample Rate.
-  Improved way to test SDK integration using xcode scheme launch arguments for testing full Network Sample Rate in xcode debug sessions.
-  Deprecated customCategories, customNumbers and customVariables Page class of BTTimer. Use BlueTriangle 'setCustomVariables(_ variables : [:] )' methods instead.

# Blue Triangle 3.12.0, Oct 23 2024
### New Features
- Added support for Custom Variables

# Blue Triangle 3.11.0, Oct 7 2024
### New Features
-  Adding support for collecting Cellular Network Type

# Blue Triangle 3.10.1, Sep 23 2024
### New Features
-  Adding support for collecting iOS Device Model

# Blue Triangle 3.10.0, Sep 4 2024
### New Features
-  Added session expiry after 30 minutes of inactivity
-  Session will now be maintained within 30 minutes duration across app background, app kills and system reboots
-  Automatically updates session in WebView on session expiry

# Blue Triangle 3.9.2, AUG 9 2024
### Bug Fixes and Improvements
- Removed Device Name from pageType field from the error request payloads

# Blue Triangle 3.9.1, JUL 26 2024
### New Features
- Added the verifySessionStitchingOnWebView function to troubleshoot Session Stitching with WKWebView
### Bug Fixes and Improvements
- Fixed an issue with Traffic Segment default value in Automatic Tracker timers
- Fixed an issue with the Memory Warning message

#Blue Triangle 3.9.0, JUL 12 2024
### New Features
- Introduced Signal Crash tracking alongside the existing crash support.

# Blue Triangle 3.8.0, JUN 17 2024
### New Features
- Added the Cart Count and Cart Count Checkout fields to the PurchaseConfirmation


# Blue Triangle 3.7.1, JUN 10 2024
### Bug Fixes and Improvements
- Fixed Xcode 15.3 SDK build issue

# Blue Triangle 3.7.0, MAY 22 2024
### New Features
- Automatic Hot and Cold Launch Time Tracking
### Bug Fixes and Improvements
- Fixed an issue with WebView not capturing network requests if Screen Tracking disabled


# Blue Triangle 3.6.0, MAY 2 2024
### New Features
- SDK can now be configured with only the Site ID, with all stat tracking enabled by default
- Added convenient function for manual network tracking with URLRequest and URLResponse
### Bug Fixes and Improvements
- Fixed bug related to disabling Network State

# Blue Triangle 3.5.1, APR 26 2024
### New Features
- Added Privacy Manifest

# Blue Triangle 3.5.0, MAR 20 2024
### New Features
- Network state capture
- WebView tracking
- Memory Warning
### Bug Fixes and Improvements
- Improved CPU and Memory Tracking feature
- Improved offline caching mechanism with the inclusion of Memory limit and Expiration.
- Added support for capturing Network Errors

# Blue Triangle : 3.4.1, SEP 21 2023
### Bug Fixes and Improvements
- Fixed edge case where Screen Tracking performance time reported incorrectly for SwiftUI views.

# Blue Triangle : 3.4.0, JUL 24 2023
### New Features
- Automated Screen View Tracking for view controllers and SwiftUI views
- Application Not Responding tracking and reporting as 'ANRWarnings'
- All crashes and ANRWarnings now correctly report the screen where the error occurs
