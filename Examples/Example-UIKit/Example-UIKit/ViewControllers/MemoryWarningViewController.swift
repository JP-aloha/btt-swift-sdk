//
//  MemoryWarningViewController.swift
//  Example-UIKit
//
//  Created by Ashok Singh on 07/01/25.
//  Copyright © 2025 Blue Triangle. All rights reserved.
//

import UIKit

class MemoryWarningViewController: UIViewController {
    
    private let memory = MemoryAllocationTest()
    
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        memory.freeAllMemoryTest()
    }
    
    private lazy var buttonStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [memoryWarningButton, infoLabel])
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 16.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var memoryWarningButton: UIButton = {
        let action = UIAction(title: "Memory Warning") { [weak self] _ in
            self?.memory.runMemoryTest()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var infoLabel: UILabel = {
           let label = UILabel()
           label.text = "Tap on Memory Warning button continuously until warning alert is not shown."
           label.textAlignment = .center
           label.font = .systemFont(ofSize: 14)
           label.textColor = .secondaryLabel
           label.numberOfLines = 0
           label.translatesAutoresizingMaskIntoConstraints = false
           return label
       }()
    
    @objc func raiseMemoryWarning(){
        let alert = UIAlertController(title: "Error", message: "Detected memory warning. ", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    deinit {
        removeObserver()
    }
}

extension MemoryWarningViewController {
    //MARK: - Memory Warning observers
       
    private func resisterObserver(){
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(raiseMemoryWarning),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }
    
    private func removeObserver(){
        NotificationCenter.default.removeObserver(self,
                                                          name: UIApplication.didReceiveMemoryWarningNotification,
                                                          object: nil)
    }
}
