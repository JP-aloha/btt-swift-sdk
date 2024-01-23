//
//  TestFullPresentViewController.swift
//
//  Created by JP on 15/05/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit
import BlueTriangle
import Combine

class TestFullPresentViewController: UIViewController {

    @IBOutlet weak var lblTitle : UILabel!
    @IBOutlet weak var lblId : UILabel!
    @IBOutlet weak var lblDesc : UILabel!
    
    private var subscriptions = [UUID: AnyCancellable]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }
    
    private func updateUI(){
        
       /* self.title = "Present FullScreen"
        
        lblTitle.text = "\(type(of: self))"
        lblId.text = "SleepTime : Heavy Run" + "\n"
        lblDesc.text = "This screen is an UIViewController sub class. Presented on UIViewController using func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) with  fullScreen modalPresentationStyle."
        
        let _ = HeavyLoop().run()*/
    }

   
    @IBAction func didSelectDissmiss(_ sender : Any){
        self.dismiss(animated: true)
    }
    
  
    @IBAction func didSelectCustomError(_ sender : Any) {
        let tracker = NetworkCaptureTracker.init(url: "http://www.127.0.0.1:10000/api/server", method: "post", requestBodylength: 9130)
        let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Fail to connect with server."])
        tracker.failled(error)
    }
    
    
    @IBAction func didSelectBtDataTaskUrl(_ sender : Any) {
        let timer = BlueTriangle.startTimer(page: Page(pageName: "TestFullPresentViewController"))
        URLSession.shared.btDataTask(with: URL(string: "https://httpbin.org/invalidendpoint")!) { data, response, error in
       
        }.resume()
    }
    
    @IBAction func didSelectBtDataTaskRequest(_ sender : Any) {
        let timer = BlueTriangle.startTimer(page: Page(pageName: "TestFullPresentViewController"))
        let request = URLRequest(url: URL(string: "http://www.127.0.0.1:10000/api/server")!)
        URLSession.shared.btDataTask(with: request){ data, response, error in
            
        }.resume()
    }
    
    @IBAction func didSelectBtData(_ sender : Any) {
        Task{
            let request = URLRequest(url: URL(string: "http://www.127.0.0.1:10000/api/server")!)
            try await URLSession.shared.btData(for: request)
        }
    }
    
    @IBAction func didSelectBtDataTaskPublisher(_ sender : Any) {
        let request = URLRequest(url: URL(string: "http://www.127.0.0.1:10000/api/server")!)
        let id = UUID()
        let publiser = URLSession.shared.btDataTaskPublisher(for: request)
            .sink { _ in
                self.removeSubscription(id: id)
            } receiveValue: { _ in}
        
        addSubscription(publiser, id: id)
    }
    
    
    @IBAction func didSelectBtDelegate(_ sender : Any) {
        Task{
            
            let session = URLSession(
                configuration: .default,
                delegate: NetworkCaptureSessionDelegate(),
                delegateQueue: nil)

            let timer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
            try await session.data(from: URL(string: "http://www.127.0.0.1:10000/api/server")!)
        }
    }
    

    @IBAction func didSelectBtDataTask(_ sender : Any) {
        let timer = BlueTriangle.startTimer(page: Page(pageName: "TestFullPresentViewController"))
    
        /*404 URLSession.shared.btDataTask(with: URL(string: "https://www.lifewire.com/computers-laptops-1233445")!) { data, response, error in
       
        }.resume()*/
        
       /*401 URLSession.shared.btDataTask(with: URL(string: "https://api.spoonacular.com/recipes/findByIngredients")!) { data, response, error in
       
        }.resume()*/
        
       /*err URLSession.shared.btDataTask(with: URL(string: "http://www.127.0.0.1:10000/api/server")!) { data, response, error in
       
        }.resume()*/
        
        let sesssion = URLSession(
            configuration: .default,
            delegate: NetworkCaptureSessionDelegate(),
            delegateQueue: nil)
        let request = URLRequest(url: URL(string: "http://www.127.0.0.1:10000/api/server")!)
        let id = UUID()
        /*let publiser = URLSession.shared.btDataTaskPublisher(for: request)
            .sink { _ in
                self.removeSubscription(id: id)
            } receiveValue: { _ in}
        
        addSubscription(publiser, id: id)*/
        
        Task{
            try await URLSession.shared.btData(for: request)
        }
    }
    
    private func addSubscription(_ cancellable: AnyCancellable, id: UUID) {
         subscriptions[id] = cancellable
    }

    private func removeSubscription(id: UUID) {
        subscriptions[id] = nil
    }
}
