//
//  Utils.swift
//  Example-UIKit
//
//  Created by admin on 15/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation
import UIKit

class Utils {

    static func displayAlert(title: String, message: String, vc: UIViewController) {

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)

        vc.present(alertController, animated: true, completion: nil)
    }

}

extension UIDevice{
    
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
