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
    
    public init(_ screenName : String){
        self.pageName = screenName
    }
    
    private func updateScreenType(){
        
        if type == ViewType.UIKit.rawValue{
            BlueTriangle.screenTracker?.setUpViewType(.UIKit)
        }
        else if type == ViewType.SwiftUI.rawValue{
            BlueTriangle.screenTracker?.setUpViewType(.SwiftUI)
        }
        else{
            BlueTriangle.screenTracker?.setUpViewType(.Manual)
        }
    }
    
    public func loadStarted() {
        self.hasViewing = true
        self.updateScreenType()
        BlueTriangle.screenTracker?.manageTimer(pageName, id: id, type: .load)
    }
    
    public func loadEnded() {
        if self.hasViewing{
            self.updateScreenType()
            BlueTriangle.screenTracker?.manageTimer(pageName, id: id, type: .finish)
        }
    }

    public func viewStart() {
        self.hasViewing = true
        self.updateScreenType()
        BlueTriangle.screenTracker?.manageTimer(pageName, id: id, type: .view)
    }
    
    public func viewingEnd() {
        if self.hasViewing{
            BlueTriangle.screenTracker?.manageTimer(pageName, id: id, type: .disapear)
            self.hasViewing = false
        }
    }
}

