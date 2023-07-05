//
//  TestsHomeViewController.swift
//  Example-UIKit
//
//  Created by admin on 14/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit
import BlueTriangle
class TestsHomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var lblRunning: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    private var timer : BTTimer?
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.setTitle("Stop", for: .selected)
        startButton.setTitle("Start", for: .normal)
        lblRunning.isHidden =  !startButton.isSelected
    }
    
    @IBAction func didSelectStart(_ sender: Any) {
        if startButton.isSelected {
            stopTimer()
        } else {
            startTimer()
        }
        startButton.isSelected = !startButton.isSelected
        lblRunning.isHidden =  !startButton.isSelected
      
    }
    private func startTimer(){
        let page = Page(pageName:"Main Thread Performance Test Page")
        self.timer = BlueTriangle.startTimer(page: page)
    }
    
    private func stopTimer(){
        if let t = timer{
            BlueTriangle.endTimer(t)
            timer = nil
        }
    }
}

extension TestsHomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ANRTestFactory().ANRTests().count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "TestsTableViewCell") as? TestsTableViewCell {
            cell.initCell(with: ANRTestFactory().ANRTests()[indexPath.row])
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "TestsTableViewCell") as? TestsTableViewCell {
            cell.titleLbl.text = "ANR Tests"
            cell.subtitleLbl.text = "Below are the ANR tests. If run while BTTimer, max main thread usage will be reported in BTTimer request."
            cell.contentView.backgroundColor = .systemGray6
            return cell.contentView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "ANRTests", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "RunTestViewController") as? RunTestViewController {
            if let presentationController = vc.presentationController as? UISheetPresentationController {
                presentationController.detents = [.medium()]
            }
            vc.currentTest = ANRTestFactory().ANRTests()[indexPath.row]
            navigationController?.present(vc, animated: true)
        }
    }
}
