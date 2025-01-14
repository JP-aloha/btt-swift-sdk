//
//  RootViewController.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 10/15/21.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import BlueTriangle
import UIKit

class RootViewController: UIViewController {

    // MARK: - Subviews
    
    private lazy var networkButton: UIButton = {
        let action = UIAction(title: "Network  ->") { [weak self] _ in
            self?.showNetwork()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var errorButton: UIButton = {
        let action = UIAction(title: "Error") { [weak self] _ in
            self?.trackError()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .orange
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var crashButton: UIButton = {
        let action = UIAction(title: "Crash") { [weak self] _ in
            self?.causeNSException()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .red
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private lazy var ANRtestButton: UIButton = {
        let action = UIAction(title: "ANR Tests  ->") { [weak self] _ in
            self?.showTestHomeVC()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .black
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var memoryWarningButton: UIButton = {
        let action = UIAction(title: "Memory Warning") { [weak self] _ in
            self?.showMemoryWarning()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .systemMint
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var cpuTestsButton: UIButton = {
        let action = UIAction(title: "CPU Tests  ->") { [weak self] _ in
            self?.cpuTestsTimer()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .brown
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var customTimerButton: UIButton = {
        let action = UIAction(title: "Custom Timer") { [weak self] _ in
            let timer = BlueTriangle.startTimer(page: Page(pageName: "Custom Timer"))
            BlueTriangle.endTimer(timer)
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .systemCyan
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var screenTrackingButton: UIButton = {
        let action = UIAction(title: "Auto Screen Tracking   ->") { [weak self] _ in
            self?.showScreenTrackingHomeVC()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .gray
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(buttonStackView)

        NSLayoutConstraint.activate([
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    private lazy var buttonStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [networkButton, errorButton, crashButton, ANRtestButton, memoryWarningButton, cpuTestsButton, customTimerButton, screenTrackingButton])
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 16.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    

    // MARK: - Actions

    private func showPhotoCollection() {
        let configuration = URLSessionConfiguration.default
        // Disable caching
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)

        let jsonPlaceholder = JSONPlaceholder(session: session)
        let imageLoader = ImageLoader(session: session)

        let viewController = PhotoCollectionViewController(
            jsonPlaceholder: jsonPlaceholder,
            imageLoader: imageLoader)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func cpuTestsTimer() {
        let viewController = CPUTestsViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func showMemoryWarning() {
        let viewController = MemoryWarningViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func showNetwork() {
        let viewController = NetworkTrackingViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func trackError() {
        let error = AppError(reason: "There was an error fooing", underlyingError: nil)
        BlueTriangle.logError(error)
    }

    private func causeNSException() {
        let array = NSArray()
        let crash = array.object(at: 99)
        print("CRASHED: \(crash)")
    }
    
    private func showTestHomeVC() {
        let storyboard = UIStoryboard(name: "ANRTests", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "TestsHomeViewController") as? TestsHomeViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func showScreenTrackingHomeVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "HomeVC") as? HomeViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
       
    }
}
