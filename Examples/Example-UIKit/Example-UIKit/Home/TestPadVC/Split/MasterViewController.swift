//
//  MasterViewController.swift
//  Copyright 2023 Blue Triangle
//  Copyright 2023 Blue Triangle
//  Created by Bhavesh B on 19/05/23.
//

import UIKit

class MasterViewController: UITableViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if indexPath.row == 0{
            cell.textLabel?.text = "Menu Detail 1"
        }else{
            cell.textLabel?.text = "Menu Detail 2"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let splitVC = self.splitViewController
        let navVC = splitVC?.viewControllers[1]  as? UINavigationController
        
        if let splitVC = self.splitViewController, let navVC = splitVC.viewControllers[1]  as? UINavigationController , let detailVC = navVC.viewControllers.first as? DetailViewController{
            if indexPath.row == 0{
                detailVC.lblDetailString?.text = "Menu Detail 1"
            }else{
                detailVC.lblDetailString?.text = "Menu Detail 2"
            }
        }
    }

}
