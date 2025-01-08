//
//  CustomTimerViewController.swift
//  Example-UIKit
//
//  Created by Ashok Singh on 08/01/25.
//  Copyright © 2025 Blue Triangle. All rights reserved.
//

import UIKit
import BlueTriangle

class CPUTestsViewController: UIViewController {
    
    private var timer : BTTimer?
    private var cpuTest = CPUUsesTest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(buttonStackView)

        NSLayoutConstraint.activate([
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            buttonStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 30),
            buttonStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -30)
        ])
    }
    
    private lazy var buttonStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [singleCore50_80_Button, singleCore_100_Button, doubleCore100_Button, heavyLoopButton])
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 16.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var singleCore50_80_Button: UIButton = {
        let action = UIAction(title: "Single Core 50-80 %") { [weak self] _ in
            self?.cpuTest.runSingleCoreFiftyToEightyPercent()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .blue
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var singleCore_100_Button: UIButton = {
        let action = UIAction(title: "Single Core 100 %") { [weak self] _ in
            self?.cpuTest.runSingleCoreHundradePercent()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .red
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var doubleCore100_Button: UIButton = {
        let action = UIAction(title: "Double Core 100 %") { [weak self] _ in
            self?.cpuTest.runDoubleCoreHundradePercent()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .brown
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var heavyLoopButton: UIButton = {
        let action = UIAction(title: "Heavy Loop") { [weak self] _ in
            self?.heavyLoopTest()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.tintColor = .orange
        return control
    }()
    
    private func heavyLoopTest(){
        
        let processInfo = ProcessInfo()
        let logicalCoresCount = ProcessInfo.processInfo.processorCount
        print("Count1 :\(processInfo.activeProcessorCount)-\(logicalCoresCount)")
        
        DispatchQueue.global().async {
            let extractTaskCombination = AlphabetCombination()
            let taskCombinations = extractTaskCombination.makeAllCombinations()
            print("Background Thread1: \(taskCombinations)")
        }
        
        DispatchQueue.global().async {
            let extractCombination = AlphabetCombination()
            let combinations = extractCombination.makeAllCombinations()
            print("Background Thread2: \(combinations)")
        }
        
        DispatchQueue.global().async {
            let extractCombination = AlphabetCombination()
            let combinations = extractCombination.makeAllCombinations()
            print("Background Thread3:  \(combinations)")
            print("Count2 :\(processInfo.activeProcessorCount)")
        }
    }
    
    
    private func startTimer(){
        self.timer = BlueTriangle.startTimer(page: Page(pageName:"Heavy Loop Test Case"))
        print("Start timer DONE")
    }
    
    private func stopTimer(){
        if let t = timer{
            print("Stop timer DONE")
            BlueTriangle.endTimer(t)
            timer = nil
        }
    }
}
