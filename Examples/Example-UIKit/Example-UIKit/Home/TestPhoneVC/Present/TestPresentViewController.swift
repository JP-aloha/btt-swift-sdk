//
//  TestPresentViewController.swift
//  Copyright 2023 Blue Triangle
//
//  Created byBhavesh B on 15/05/23.
//

import UIKit

class TestPresentViewController: UIViewController {

    @IBOutlet weak var lblTitle : UILabel!
    @IBOutlet weak var lblId : UILabel!
    @IBOutlet weak var lblDesc : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }
    
    private func updateUI(){
        
        self.title = "Present Default"
        
        lblTitle.text = "\(type(of: self))"
        lblId.text = "Id :" + "\n"  + String(describing: self)
        lblDesc.text = "This screen is an UIViewController sub class. Presented on UIViewController using func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) with  default modalPresentationStyle."
    }
   
}
