//
//  TestPadContainerViewController.swift
//  Copyright 2023 Blue Triangle
//
//  Created byBhavesh B on 19/05/23.
//

import UIKit

class TestPadContainerViewController: UIViewController {

    @IBOutlet weak var firstContainer : UIView!
    @IBOutlet weak var secondContainer : UIView!
    @IBOutlet weak var segmentControll : UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateContainerUI()
        // Do any additional setup after loading the view.
    }
    
    fileprivate func updateContainerUI() {
        self.title = "Subview Using ContainerView"
        if segmentControll.selectedSegmentIndex == 0{
            firstContainer.isHidden = false
            secondContainer.isHidden = true
        }else{
            firstContainer.isHidden = true
            secondContainer.isHidden = false
        }
    }
    
    @IBAction func didSelectSegmentControll(_ sender: UISegmentedControl) {
        updateContainerUI()
    }

}
