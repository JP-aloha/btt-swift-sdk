# Blue Triangle 3.13.1 Latest
- [changed] Ability to remotely ignore Screens.

# Blue Triangle 3.13.0
- [changed] Ability to remotely overwrite Network Sample Rate.
- [changed] Improved way to test SDK integration using xcode scheme launch arguments for testing full Network Sample Rate in xcode debug sessions.
- [removed] Deprecated customCategories, customNumbers and customVariables Page class of BTTimer. Use BlueTriangle 'setCustomVariables(_ variables : [:] )' methods instead.

# Blue Triangle 3.12.0
- [added] Added support for Custom Variables

# Blue Triangle 3.11.0
- [added] Adding support for collecting Cellular Network Type

# Blue Triangle 3.10.1
- [added] Adding support for collecting iOS Device Model

# Blue Triangle 3.10.0
- [added] Added session expiry after 30 minutes of inactivity
- [changed] Session will now be maintained within 30 minutes duration across app background, app kills and system reboots
- [changed] Automatically updates session in WebView on session expiry

# Blue Triangle 3.9.2
- [fixed] Removed Device Name from pageType field from the error request payloads

# Blue Triangle 3.9.1
- [added] Added the verifySessionStitchingOnWebView function to troubleshoot Session Stitching with WKWebView
- [fixed] Fixed an issue with Traffic Segment default value in Automatic Tracker timers
- [fixed] Fixed an issue with the Memory Warning message

#Blue Triangle 3.9.0
- [changed] Introduced Signal Crash tracking alongside the existing crash support.

# Blue Triangle 3.8.0
- [added] Added the Cart Count and Cart Count Checkout fields to the PurchaseConfirmation


# Blue Triangle 3.7.1
- [changed] Fixed Xcode 15.3 SDK build issue

# Blue Triangle 3.7.0
- [added] Automatic Hot and Cold Launch Time Tracking
- [fixed] Fixed an issue with WebView not capturing network requests if Screen Tracking disabled


# Blue Triangle 3.6.0
- [changed] SDK can now be configured with only the Site ID, with all stat tracking enabled by default
- [changed] Added convenient function for manual network tracking with URLRequest and URLResponse
- [fixed] Fixed bug related to disabling Network State

# Blue Triangle 3.5.1
- [added] Added Privacy Manifest

# Blue Triangle 3.5.0
- [added] Network state capture
- [added] WebView tracking
- [added] Memory Warning
- [fixed] Improved CPU and Memory Tracking feature
- [fixed] Improved offline caching mechanism with the inclusion of Memory limit and Expiration.
- [fixed] Added support for capturing Network Errors

# Blue Triangle : 3.4.1
- [fixed] Fixed edge case where Screen Tracking performance time reported incorrectly for SwiftUI views.

# Blue Triangle : 3.4.0
- [added] Automated Screen View Tracking for view controllers and SwiftUI views
- [added] Application Not Responding tracking and reporting as 'ANRWarnings'
- [fixed] All crashes and ANRWarnings now correctly report the screen where the error occurs
