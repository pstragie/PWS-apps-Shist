//
//  ListCellModel.swift
//  SharedList
//
//  Created by Pieter Stragier on 07/11/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import Foundation
import UIKit

protocol ListCellModelDelegate: class {
    func numberOfItems(items:Int, planned:Int, done:Int)
}
class ListCellModel: UITableViewCell {
    
    static let reuseIdentifier = "ListNames"
    var delegatePersonalCell: PersonalListViewController?
    var delegateSharedCell: SharedListViewController?
    var items:Int?
    var planned:Int?
    var done:Int?
    
    @IBOutlet weak var listContentView: UIView!
    @IBOutlet weak var bckGroundView: UIView!
    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var listName: UILabel!
    @IBOutlet weak var numberOfItems: UILabel!
    // MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
}
