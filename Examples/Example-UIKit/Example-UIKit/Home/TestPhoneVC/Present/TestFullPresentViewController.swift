//
//  TestFullPresentViewController.swift
//
//  Created by JP on 15/05/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit
import BlueTriangle
import Combine

class TestFullPresentViewController: UIViewController {
    
    @IBOutlet weak var lblTitle : UILabel!
    @IBOutlet weak var lblId : UILabel!
    @IBOutlet weak var lblDesc : UILabel!
    
    private var subscriptions = [UUID: AnyCancellable]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }
    
    private func updateUI(){
        
        self.title = "Present FullScreen"
        
        lblTitle.text = "\(type(of: self))"
        lblId.text = "Id :" + "\n"  + String(describing: self)
        lblDesc.text = "This screen is an UIViewController sub class. Presented on UIViewController using func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) with  fullScreen modalPresentationStyle."
    }
    
    
    @IBAction func didSelectDissmiss(_ sender : Any){
        self.dismiss(animated: true)
    }
}
