//
//  TestPadFormSheetPresentViewController.swift
//  Copyright 2023 Blue Triangle
//
//  Created byBhavesh B on 19/05/23.
//

import UIKit

class TestPadFormSheetPresentViewController: UIViewController {
    @IBOutlet weak var lblTitle : UILabel!
    @IBOutlet weak var lblId : UILabel!
    @IBOutlet weak var lblDesc : UILabel!
    @IBOutlet weak var lblVcTitle : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }
    
    private func updateUI(){
        
        self.lblVcTitle.text = "Present Form Sheet"
        
        lblTitle.text = "\(type(of: self))"
        lblId.text = "Id :" + "\n"  + String(describing: self)
        lblDesc.text = "This screen is an UIViewController sub class. Presented on UIViewController using func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) with  default modalPresentationStyle."
    }
    
    @IBAction func didSelectDissmiss(_ sender : Any){
        self.dismiss(animated: true)
    }
}
