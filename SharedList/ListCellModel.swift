//
//  ListCellModel.swift
//  SharedList
//
//  Created by Pieter Stragier on 07/11/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import Foundation
import UIKit

class ListCellModel: UITableViewCell {
    
    static let reuseIdentifier = "ListNames"
    
    @IBOutlet weak var listContentView: UIView!
    @IBOutlet weak var listName: UILabel!
    
    // MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
