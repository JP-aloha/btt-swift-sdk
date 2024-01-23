//
//  SlideViewController.swift
//
//  Created by JP on 15/05/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit

class SlideViewController: UIViewController {

    @IBOutlet weak var lblParent : UILabel!
    @IBOutlet weak var lblTitle : UILabel!
    @IBOutlet weak var lblId : UILabel!
    @IBOutlet weak var lblDesc : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }
    
    private func updateUI(){
        
        lblParent.text = "Parent : PagerViewController"
        lblTitle.text = "\(type(of: self))"
        lblId.text = "Id :" + "\n"  + String(describing: self)
        lblDesc.text = "This screen is an UIViewController sub class. Sliding on UIViewController Scroll View."
    }
   
    static func getSlides()-> [SlideViewController]{
        let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
       
        let slide1 = storyBoard.instantiateViewController(withIdentifier: String(describing: SlideViewController.self)) as! SlideViewController
        //slide1.loadView()
        //slide1.lblTitle.text = "Page 1"
   
        let slide2 = storyBoard.instantiateViewController(withIdentifier: String(describing: SlideViewController.self)) as! SlideViewController
       // slide2.loadView()
        //slide2.lblTitle.text = "Page 2"

        let slide3 = storyBoard.instantiateViewController(withIdentifier: String(describing: SlideViewController.self)) as! SlideViewController
       // slide3.loadView()
        //slide3.lblTitle.text = "Page 3"
        return [slide1, slide2, slide3]
    }
}
