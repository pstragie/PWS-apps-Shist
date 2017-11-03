//
//  CellModel.swift
//  SharedList
//
//  Created by Pieter Stragier on 30/10/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import Foundation
import UIKit

class CellModel: UITableViewCell {
    
    // MARK: - Properties
    
    static let reuseIdentifier = "ListsCell"

    @IBOutlet weak var planned: UIButton!
    @IBOutlet weak var done: UIButton!
    @IBOutlet weak var listitem: UILabel!
    
    // MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
