//
//  BTTScreenTracker.swift
//
//
//  Created by Ashok Singh on 06/11/23.
//

import Foundation

public class BTTScreenTracker{
    
    private var hasViewing = false
    private var bttTracker = BTTScreenLifecycleTracker.shared
    private var id = "\(Identifier.random())"
    private var pageName : String
    public  var type  = ViewType.Manual.rawValue
    
    public init(_ screenName : String){
        self.pageName = screenName
    }
    
    private func updateScreenType(){
        
        if type == ViewType.UIKit.rawValue{
            self.bttTracker.setUpViewType(.UIKit)
        }
        else if type == ViewType.SwiftUI.rawValue{
            self.bttTracker.setUpViewType(.SwiftUI)
        }
        else{
            self.bttTracker.setUpViewType(.Manual)
        }
    }
    
    public func loadStarted() {
        self.hasViewing = true
        self.updateScreenType()
        bttTracker.manageTimer(pageName, id: id, type: .load)
    }
    
    public func loadEnded() {
        if self.hasViewing{
            self.updateScreenType()
            bttTracker.manageTimer(pageName, id: id, type: .finish)
        }
    }

    public func viewStart() {
        self.hasViewing = true
        self.updateScreenType()
        bttTracker.manageTimer(pageName, id: id, type: .view)
    }
    
    public func viewingEnd() {
        if self.hasViewing{
            bttTracker.manageTimer(pageName, id: id, type: .disapear)
            self.hasViewing = false
        }
    }
}

