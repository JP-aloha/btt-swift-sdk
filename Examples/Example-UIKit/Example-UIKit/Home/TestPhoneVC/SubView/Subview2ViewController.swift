//
//  Subview2ViewController.swift
//  Copyright 2023 Blue Triangle
//
//  Created byBhavesh B on 16/05/23.
//

import UIKit

class Subview2ViewController: UIViewController {

    @IBOutlet weak var lblParent : UILabel!
    @IBOutlet weak var lblTitle : UILabel!
    @IBOutlet weak var lblId : UILabel!
    @IBOutlet weak var lblDesc : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }
    
    private func updateUI(){
        lblParent.text = "Parent : TestSubviewViewController"
        lblTitle.text = "\(type(of: self))"
        lblId.text = "Id :" + "\n"  + String(describing: self)
        lblDesc.text = "This screen is an UIViewController sub class. Subview on UIViewController using VStack."
    }
}
