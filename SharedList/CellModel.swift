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

    @IBOutlet var planned: UIButton!
    @IBOutlet var done: UIButton!
    @IBOutlet var listitem: UITextView!
    @IBOutlet var delete: UIButton!
    
    // MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
