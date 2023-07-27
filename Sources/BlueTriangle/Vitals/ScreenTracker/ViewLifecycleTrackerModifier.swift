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
                        BTTScreenLifecycleTracker.shared.loadFinish(id, name)
                        BTTScreenLifecycleTracker.shared.viewStart(id, name)
                    }
                })
                .onAppear {
                    id = UUID().uuidString
                    if let id = self.id{
                        BTTScreenLifecycleTracker.shared.loadStarted(id, name)
                    }
                }
                .onDisappear{
                    if let id = self.id{
                        BTTScreenLifecycleTracker.shared.viewingEnd(id, name)
                    }
                }
        }
        else{
            content
                .onAppear {
                    id = UUID().uuidString
                    if let id = self.id{
                        BTTScreenLifecycleTracker.shared.viewStart(id, name)
                    }
                    Task{
                        if let id = self.id{
                            BTTScreenLifecycleTracker.shared.loadFinish(id, name)
                            BTTScreenLifecycleTracker.shared.viewStart(id, name)
                        }
                    }
                }
                .onDisappear{
                    if let id = self.id{
                        BTTScreenLifecycleTracker.shared.viewingEnd(id, name)
                    }
                }
        }
    }
}

public extension View {
    ///Uses for manual screen tracking to log individual views in SwiftUI.
    ///To track screen, call "trackScreen(_ screenName: String)" on view which screen compose(which life cycle you want to track) like VStack().trackScreen("ContentView") or  ContentView().trackScreen("ContentView")
    ///This method track screen when this view appears on screen
    
    func bttTrackScreen(_ screenName: String) -> some View {
        BTTScreenLifecycleTracker.shared.setUpViewType(.SwiftUI)
        return modifier(ViewLifecycleTrackerModifier(name: screenName))
    }
}


