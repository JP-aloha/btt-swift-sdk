//
//  ViewLifecycleTrackerModifier.swift
//
//
//  Created by JP on 20/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

  import SwiftUI

internal struct ViewLifecycleTrackerModifier: ViewModifier {
    let name: String
    @State var id : String?
    
    func body(content: Content) -> some View {
            
        if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *){
            content
                .task({
                    if let id = self.id{
                        BlueTriangle.screenTracker?.loadFinish(id, name)
                        BlueTriangle.screenTracker?.viewStart(id, name)
                    }
                })
                .onAppear {
                    id = UUID().uuidString
                    if let id = self.id{
                        if let tracking = BlueTriangle.screenTracker {
                            tracking.loadStarted(id, name)
                            BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.onAppear, className: name))
                        }
                    }
                }
                .onDisappear{
                    if let id = self.id{
                        if let tracking = BlueTriangle.screenTracker {
                            tracking.viewingEnd(id, name)
                            BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.onDisappear, className: name))
                        }
                    }
                }
        }
        else{
            content
                .onAppear {
                    id = UUID().uuidString
                    if let id = self.id{
                        if let tracking = BlueTriangle.screenTracker {
                            tracking.viewStart(id, name)
                            BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.onAppear, className: name))
                        }
                    }
                    Task{
                        if let id = self.id{
                            BlueTriangle.screenTracker?.loadFinish(id, name)
                            BlueTriangle.screenTracker?.viewStart(id, name)
                        }
                    }
                }
                .onDisappear{
                    if let id = self.id{
                        if let tracking = BlueTriangle.screenTracker {
                            tracking.viewingEnd(id, name)
                            BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.onDisappear, className: name))
                        }
                    }
                }
        }
    }
}

public struct BTTTrack<Content: View>: View {

    private let screenName: String
    private let content: Content

    public init(_ screenName: String, @ViewBuilder content: () -> Content) {
        self.screenName = screenName
        self.content    = content()
    }

    public var body: some View {
        content
            .bttTrackScreen(screenName)
    }
}

public extension View {
    
    private func shouldTrackScreen(_ name : String) -> Bool{

        setUpScreenType()
        
        // Ignore any view explicitly listed in a developer exclusion list or remote config ignore list
        if let sessionData = BlueTriangle.sessionData(), sessionData.ignoreViewControllers.contains(name) {
             return false
         }
        
        return true
    }
    
   private func setUpScreenType(){
        //SetUp View Type
       BlueTriangle.screenTracker?.setUpScreenType(.SwiftUI)
    }
    
    ///Uses for manual screen tracking to log individual views in SwiftUI.
    ///To track screen, call "trackScreen(_ screenName: String)" on view which screen compose(which life cycle you want to track) like VStack().trackScreen("ContentView") or  ContentView().trackScreen("ContentView")
    ///This method track screen when this view appears on screen
    
    
    @ViewBuilder
    func bttTrackScreen(_ screenName: String) -> some View {
        if shouldTrackScreen(screenName) {
             self.modifier(ViewLifecycleTrackerModifier(name: screenName))
        } else {
            self
        }
    }
}
