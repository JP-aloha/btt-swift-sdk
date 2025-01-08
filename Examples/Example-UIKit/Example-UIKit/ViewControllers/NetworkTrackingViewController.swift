//
//  NetworkTrackingViewController.swift
//  Example-UIKit
//
//  Created by Ashok Singh on 07/01/25.
//  Copyright © 2025 Blue Triangle. All rights reserved.
//

import UIKit
import BlueTriangle
import Combine

class NetworkTrackingViewController: UIViewController {

    private var subscriptions = [UUID: AnyCancellable]()
    
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
        let view = UIStackView(arrangedSubviews: [multiNetworkButton , btDataTaskButton, btDataPublisherButton, btDataDelegateButton, btCustomNetworkError])
        view.axis = .vertical
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 16.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    

    private lazy var multiNetworkButton: UIButton = {
        let action = UIAction(title: "Multi Network  ->") { [weak self] _ in
            self?.showPhotoCollection()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var btDataTaskButton: UIButton = {
        let action = UIAction(title: "Network Data Task") { [weak self] _ in
            let request = URLRequest(url: URL(string: "http://www.127.0.0.1:10001/api/server")!)
            URLSession.shared.btDataTask(with: request){ data, response, error in
            }.resume()
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .red
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var btDataPublisherButton: UIButton = {
        let action = UIAction(title: "Network Data Publisher") { [weak self] _ in
            let request = URLRequest(url: URL(string: "http://www.127.0.0.1:10002/api/server")!)
            let id = UUID()
            let publiser = URLSession.shared.btDataTaskPublisher(for: request)
                .sink { _ in
                    self?.removeSubscription(id: id)
                } receiveValue: { _ in}
            
            self?.addSubscription(publiser, id: id)
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .orange
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var btDataDelegateButton: UIButton = {
        let action = UIAction(title: "Network Data Delegate") { [weak self] _ in
            Task{
                let session = URLSession(
                    configuration: .default,
                    delegate: NetworkCaptureSessionDelegate(),
                    delegateQueue: nil)

                let _ = try await session.data(from: URL(string: "http://www.127.0.0.1:10003/api/server")!)
            }
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .brown
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var btCustomNetworkError: UIButton = {
        let action = UIAction(title: "Custom Network Error") { [weak self] _ in
            let tracker = NetworkCaptureTracker.init(url: "http://www.127.0.0.1:10000/api/server", method: "post", requestBodylength: 9130)
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Fail to connect with server."])
            tracker.failled(error)
        }
        let control = UIButton(configuration: .filled(), primaryAction: action)
        control.tintColor = .systemGray
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

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
    
    private func addSubscription(_ cancellable: AnyCancellable, id: UUID) {
         subscriptions[id] = cancellable
    }

    private func removeSubscription(id: UUID) {
        subscriptions[id] = nil
    }
}
