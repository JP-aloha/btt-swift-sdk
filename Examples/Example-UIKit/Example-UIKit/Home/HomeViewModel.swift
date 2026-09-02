//
//  HomeViewModel.swift
//
//  Created by JP on 15/05/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation
import UIKit

class HomeViewModel : NSObject {
    

    func numberOfSection() -> Int{
       return 1
    }
    
    @MainActor func numberOfRow() -> Int{
        return homeItems().count
    }
    
    @MainActor func homeItems() -> [String]{
        var items = UIDevice.isIPad
            ? ["Test Push" , "Test Present", "Test Full Present", "Test Container","Test Tab", "Pager", "Sub View", "Split View", "Hitch"]
            : ["Test Push" , "Test Present", "Test Full Present", "Test Container","Test Tab", "Pager", "Sub View", "Hitch"]
        #if DEBUG
        items.append("Animation Hitch")
        #endif
        return items
    }
    
    @MainActor func getHomeItem(_ item : String) -> UIViewController?{
        let storyboard = UIStoryboard(name: UIDevice.isIPhone ? "Main" : "Main_iPad", bundle: nil)
        let itemVC = storyboard.instantiateViewController(withIdentifier: item)
        return itemVC
    }
    
    @MainActor func getHomeTabView(_ item : String) -> UITabBarController?{
        let storyboard = UIStoryboard(name: UIDevice.isIPhone ? "Main" : "Main_iPad", bundle: nil)
        let itemVC = storyboard.instantiateViewController(withIdentifier: item) as? UITabBarController
        return itemVC
    }
    
    @MainActor func getSplitView(_ item : String) -> TestSplitViewController?{
        let storyboard = UIStoryboard(name: UIDevice.isIPhone ? "Main" : "Main_iPad", bundle: nil)
        let itemVC = storyboard.instantiateViewController(withIdentifier: item) as? TestSplitViewController
        return itemVC
    }
}
