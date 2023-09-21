//
//  RunTestViewController.swift
//  Example-UIKit
//
//  Created by JP on 15/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit

class RunTestViewController: UIViewController {

    @IBOutlet weak var subtitlelbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var scheduleEventButton: UIButton!
    
    var selectedEvent: TestScheduler.Event?
    var currentTest: BTTTestCase?
    var menuItems: [UIAction] {
        return [
            
            UIAction(title: TestScheduler.Event.OnAppLaunch.rawValue, handler: { [ weak self] _ in
                self?.selectedEvent = .OnAppLaunch
                self?.scheduleEventButton.setTitle(self?.selectedEvent?.rawValue, for: .normal)
            }),
            UIAction(title: TestScheduler.Event.OnBecomingActive.rawValue, handler: { [ weak self] _ in
                self?.selectedEvent = .OnBecomingActive
                self?.scheduleEventButton.setTitle(self?.selectedEvent?.rawValue, for: .normal)
            }),
            UIAction(title: TestScheduler.Event.OnResumeFromBackground.rawValue, handler: { [ weak self] _ in
                self?.selectedEvent = .OnResumeFromBackground
                self?.scheduleEventButton.setTitle(self?.selectedEvent?.rawValue, for: .normal)
            })
        ]
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLbl.text = currentTest?.name
        self.subtitlelbl.text = currentTest?.description
        self.scheduleEventButton.menu = UIMenu(children: menuItems)
    }
    
    @IBAction func didSelectClose(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func didSelectRun(_ sender: Any) {
       _ = currentTest?.run()
    }
    
    @IBAction func didSelectSchedule(_ sender: Any) {
        guard let selectedEvent = selectedEvent else {
            Utils.displayAlert(title: "", message: "Please Select event", vc: self)
            return
        }
        
        if let currentTest = currentTest {
            TestScheduler.schedule(task: currentTest, event: selectedEvent)
        }
    }
    
}
