//
//  TestSubviewViewController.swift
//
//  Created by JP on 15/05/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit

class TestSubviewViewController: UIViewController {

    @IBOutlet weak var segmentControll : UISegmentedControl!
    @IBOutlet weak var containerView: UIStackView!
    private var currentChildControllers: [UIViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateSubviewUI()
    }

    fileprivate func updateSubviewUI() {
        
        self.title = "Subview Using VStack"
        
        if segmentControll.selectedSegmentIndex == 0{
            self.installSubview1Controller()
        }else{
            self.installSubview2Controller()
        }
    }
    
    @IBAction func didSelectSegmentControll(_ sender: UISegmentedControl) {
        updateSubviewUI()
    }
}

extension TestSubviewViewController{
    
    private static func subview1VC() -> Subview1ViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: Subview1ViewController.self)) as! Subview1ViewController
        return vc
    }
    
    private static func subview2VC() -> Subview2ViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier:  String(describing: Subview2ViewController.self)) as! Subview2ViewController
        return vc
    }
    
    private func replaceChildControllers(with childControllers: [UIViewController]) {
        
        currentChildControllers.forEach {
            $0.removeFromParent()
            if let view = $0.view {
                containerView.removeArrangedSubview(view)
                view.removeFromSuperview()
            } else {
                //Nothing log
            }
        }
        currentChildControllers = childControllers
        
        childControllers.forEach { controller in
            guard let view = controller.view else { return }
            view.backgroundColor = .clear
            containerView.addArrangedSubview(view)
            let constraint = view.widthAnchor.constraint(equalTo: containerView.widthAnchor)
            constraint.isActive = true
            addChild(controller)
        }
    }
    
    private func installSubview1Controller() {
        let subview1 = TestSubviewViewController.subview1VC()
        replaceChildControllers(with: [subview1])
    }
    
    private func installSubview2Controller() {
        let subview2 = TestSubviewViewController.subview2VC()
        replaceChildControllers(with: [subview2])
    }
}
