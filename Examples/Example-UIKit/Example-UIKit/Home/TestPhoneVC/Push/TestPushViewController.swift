//
//  TestPushViewController.swift
//  Copyright 2023 Blue Triangle
//
//  Created byBhavesh B on 16/05/23.
//

import UIKit

class TestPushViewController: UIViewController {

    @IBOutlet weak var lblTitle : UILabel!
    @IBOutlet weak var lblId : UILabel!
    @IBOutlet weak var lblDesc : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }
    
    private func updateUI(){
        
        self.title = "Push"
        
        lblTitle.text = "\(type(of: self))"
        lblId.text = "SleepTime : 2 Sec"  + "\n"
        lblDesc.text = "This screen is an UIViewController sub class. Pushed on UINavigationController using func pushViewController(_ viewController: UIViewController, animated: Bool)"
        
        Thread.sleep(forTimeInterval: 2)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //some calculation
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //load data from cloud
    }
}
