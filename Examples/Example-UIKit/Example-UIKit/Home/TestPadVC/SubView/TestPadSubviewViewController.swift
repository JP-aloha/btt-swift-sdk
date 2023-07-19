//
//  TestPadSubviewViewController.swift
//  Copyright 2023 Blue Triangle
//
//  Created byBhavesh B on 19/05/23.
//

import UIKit

class TestPadSubviewViewController: UIViewController {

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

extension TestPadSubviewViewController{
    
    private static func subview1VC() -> Subview1PadViewController {
        let storyboard = UIStoryboard(name: "Main_iPad", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: String(describing: Subview1PadViewController.self)) as! Subview1PadViewController
        return vc
    }
    
    private static func subview2VC() -> Subview2PadViewController {
        let storyboard = UIStoryboard(name: "Main_iPad", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier:  String(describing: Subview2PadViewController.self)) as! Subview2PadViewController
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
        let subview1 = TestPadSubviewViewController.subview1VC()
        replaceChildControllers(with: [subview1])
    }
    
    private func installSubview2Controller() {
        let subview2 = TestPadSubviewViewController.subview2VC()
        replaceChildControllers(with: [subview2])
    }
}
