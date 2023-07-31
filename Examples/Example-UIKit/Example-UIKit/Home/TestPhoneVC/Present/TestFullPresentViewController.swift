//
//  TestFullPresentViewController.swift
//  Copyright 2023 Blue Triangle
//
//  Created byBhavesh B on 15/05/23.
//

import UIKit

class TestFullPresentViewController: UIViewController {

    @IBOutlet weak var lblTitle : UILabel!
    @IBOutlet weak var lblId : UILabel!
    @IBOutlet weak var lblDesc : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }
    
    private func updateUI(){
        
        self.title = "Present FullScreen"
        
        lblTitle.text = "\(type(of: self))"
        lblId.text = "SleepTime : Heavy Run" + "\n"
        lblDesc.text = "This screen is an UIViewController sub class. Presented on UIViewController using func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) with  fullScreen modalPresentationStyle."
        
        let _ = HeavyLoop().run()
    }

   
    @IBAction func didSelectDissmiss(_ sender : Any){
        self.dismiss(animated: true)
    }
}
