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

    private lazy var galleryButton: UIButton = {
        let action = UIAction(title: "Gallery") { [weak self] _ in
            self?.showPhotoCollection()
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
        let action = UIAction(title: "ANR Tests") { [weak self] _ in
            self?.showTestHomeVC()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .black
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [galleryButton, errorButton, crashButton])
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 16.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
}
