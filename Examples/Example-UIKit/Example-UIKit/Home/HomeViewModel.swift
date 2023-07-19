//
//  HomeViewModel.swift
//  Copyright 2023 Blue Triangle
//
//  Created by Bhavesh B on 11/05/23.
//

import Foundation
import UIKit

class HomeViewModel : NSObject {
    

    func numberOfSection() -> Int{
       return 1
    }
    
    func numberOfRow() -> Int{
        return homeItems().count
    }
    
    func homeItems() -> [String]{
        if UIDevice.isIPad{
            return ["Test Push" , "Test Present", "Test Full Present", "Test Container","Test Tab", "Pager", "Sub View", "Split View"]
        }else{
            return ["Test Push" , "Test Present", "Test Full Present", "Test Container","Test Tab", "Pager", "Sub View"]
        }
    }
    
    func getHomeItem(_ item : String) -> UIViewController?{
        let storyboard = UIStoryboard(name: UIDevice.isIPhone ? "Main" : "Main_iPad", bundle: nil)
        let itemVC = storyboard.instantiateViewController(withIdentifier: item)
        return itemVC
    }
    
    func getHomeTabView(_ item : String) -> UITabBarController?{
        let storyboard = UIStoryboard(name: UIDevice.isIPhone ? "Main" : "Main_iPad", bundle: nil)
        let itemVC = storyboard.instantiateViewController(withIdentifier: item) as? UITabBarController
        return itemVC
    }
    
    func getSplitView(_ item : String) -> TestSplitViewController?{
        let storyboard = UIStoryboard(name: UIDevice.isIPhone ? "Main" : "Main_iPad", bundle: nil)
        let itemVC = storyboard.instantiateViewController(withIdentifier: item) as? TestSplitViewController
        return itemVC
    }
}
