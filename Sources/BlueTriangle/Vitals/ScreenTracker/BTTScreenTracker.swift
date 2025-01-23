//
//  BTTScreenTracker.swift
//
//
//  Created by Ashok Singh on 06/11/23.
//

import Foundation

public class BTTScreenTracker{
    
    private var hasViewing = false
    private var id = "\(Identifier.random())"
    private var pageName : String
    public  var type  = ViewType.Manual.rawValue
    private var tracker : BTTScreenLifecycleTracker?
    
   // Add local object of
    public init(_ screenName : String){
        self.pageName = screenName
        self.tracker = BlueTriangle.screenTracker
    }
    
    private func updateScreenType(){
        
        if type == ViewType.UIKit.rawValue{
            self.tracker?.setUpViewType(.UIKit)
        }
        else if type == ViewType.SwiftUI.rawValue{
            self.tracker?.setUpViewType(.SwiftUI)
        }
        else{
            self.tracker?.setUpViewType(.Manual)
        }
    }
    
    public func loadStarted() {
        self.hasViewing = true
        self.updateScreenType()
        self.tracker?.manageTimer(pageName, id: id, type: .load)
    }
    
    public func loadEnded() {
        if self.hasViewing{
            self.updateScreenType()
            self.tracker?.manageTimer(pageName, id: id, type: .finish)
        }
    }

    public func viewStart() {
        self.hasViewing = true
        self.updateScreenType()
        self.tracker?.manageTimer(pageName, id: id, type: .view)
    }
    
    public func viewingEnd() {
        if self.hasViewing{
            self.tracker?.manageTimer(pageName, id: id, type: .disapear)
            self.hasViewing = false
        }
    }
}

