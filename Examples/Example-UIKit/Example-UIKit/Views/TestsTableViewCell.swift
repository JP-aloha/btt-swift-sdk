//
//  TestsTableViewCell.swift
//  Example-UIKit
//
//  Created by admin on 14/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit

class TestsTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var subtitleLbl: UILabel!
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func initCell(with testData: BTTTestCase) {
        titleLbl.text = testData.name
        subtitleLbl.text = testData.description
    }
}
