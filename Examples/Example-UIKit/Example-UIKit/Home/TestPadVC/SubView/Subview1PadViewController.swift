//
//  Subview1PadViewController.swift
//  Copyright 2023 Blue Triangle
//
//  Created byBhavesh B on 19/05/23.
//

import UIKit

class Subview1PadViewController: UIViewController {
    
     @IBOutlet weak var lblParent : UILabel!
     @IBOutlet weak var lblTitle : UILabel!
     @IBOutlet weak var lblId : UILabel!
     @IBOutlet weak var lblDesc : UILabel!
         
     override func viewDidLoad() {
         super.viewDidLoad()
         self.updateUI()
     }
     
     private func updateUI(){
         
         self.title = "Container Subview"
         lblParent.text = "Parent : TestSubviewViewController"
         lblTitle.text = "\(type(of: self))"
         lblId.text = "Id :" + "\n"  + String(describing: self)
         lblDesc.text = "This screen is an UIViewController sub class. Subview on UIViewController using VStack."
     }
    
}
