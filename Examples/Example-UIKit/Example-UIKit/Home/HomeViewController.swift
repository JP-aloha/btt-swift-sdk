//
//  ViewController.swift
//  Copyright 2023 Blue Triangle
//
//  Created by Bhavesh B on 11/05/23.
//

import UIKit

class HomeViewController: UIViewController {
    
    private let model = HomeViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Home"
        
        Thread.sleep(forTimeInterval: 2)
    }
                                                                
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource{
      //  MARK: Tableview Delegate & DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return model.numberOfSection()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.numberOfRow()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = model.homeItems()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeCell")!
        cell.textLabel?.text = item
        cell.accessoryType = .disclosureIndicator
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = model.homeItems()[indexPath.row]
        
        if item == "Test Present"{
            if let vc = model.getHomeItem(item){
                self.present(vc, animated: true)
            }
        }else if item == "Test Tab"{
            if let vc = model.getHomeTabView(item){
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        else if item == "Split View"{
            if let vc = model.getSplitView(item){
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
        }
        else if item == "Test Full Present"{
            if let vc = model.getHomeItem(item){
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
        }else{
            if let vc = model.getHomeItem(item){
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

