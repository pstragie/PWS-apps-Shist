//
//  CellModel.swift
//  SharedList
//
//  Created by Pieter Stragier on 30/10/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import Foundation
import UIKit

protocol CellModelDelegate: class {
    func didTapBinItem(index: IndexPath)
    func plannedChanged(index: IndexPath, bool: Bool)
    func doneChanged(index: IndexPath, bool: Bool)
}
class CellModel: UITableViewCell {
    
    // MARK: - Properties
    
    static let reuseIdentifier = "ListsCell"
    var plannedWasChecked: Bool = false
    var delegateCell: PersonalListsViewController?
    var indexPath: IndexPath?
    
    @IBOutlet weak var planned: UIButton!
    @IBOutlet weak var done: UIButton!
    @IBOutlet weak var listitem: UILabel!
    @IBOutlet weak var listinfo: UILabel!
    @IBOutlet weak var delButton: UIButton!

    @IBOutlet weak var bellButton: UIButton!
    @IBOutlet weak var itemCellView: UIView!
    
    @IBAction func bellButtonTapped(_ sender: UIButton) {
        delegateCell?.didTapBellButton(index: indexPath!)
    }
    @IBAction func delButton(_ sender: UIButton) {
        delButton.setImage(#imageLiteral(resourceName: "bin"), for: .normal)
        delButton.setImage(#imageLiteral(resourceName: "bin_open"), for: .highlighted)
        delegateCell?.didTapBinItem(index: indexPath!)
    }
    
    @IBAction func doneButton(_ sender: UIButton) {
        planned.isEnabled = true
        if done.currentImage == #imageLiteral(resourceName: "checkbox-empty") {
            done.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
            let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: listitem.text!)
            attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 2, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(NSStrikethroughColorAttributeName, value: UIColor.green, range: NSMakeRange(0, attributeString.length))
            listitem.attributedText = attributeString
            planned.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
            delegateCell?.doneChanged(index: indexPath!, bool: true)
            planned.isEnabled = false
        } else {
            done.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
            listitem.text = listitem.text!
            if plannedWasChecked == false {
                planned.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
            } else {
                if planned.currentImage == #imageLiteral(resourceName: "checkbox-filled") {
                    let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: listitem.text!)
                    attributeString.addAttribute(NSForegroundColorAttributeName, value: UIColor.black, range: NSMakeRange(0, attributeString.length))
                    attributeString.addAttribute(NSBackgroundColorAttributeName, value: UIColor.orange, range: NSMakeRange(0, attributeString.length))
                    listitem.attributedText = attributeString
                } else {
                    listitem.text = listitem.text!
                }

            }
            delegateCell?.doneChanged(index: indexPath!, bool: false)
            planned.isEnabled = true
        }
    }
    @IBAction func plannedButton(_ sender: UIButton) {
        if planned.currentImage == #imageLiteral(resourceName: "checkbox-empty") {
            delegateCell?.plannedChanged(index: indexPath!, bool: true)
            planned.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
            let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: listitem.text!)
            attributeString.addAttribute(NSForegroundColorAttributeName, value: UIColor.black, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(NSBackgroundColorAttributeName, value: UIColor.orange, range: NSMakeRange(0, attributeString.length))
            listitem.attributedText = attributeString
            plannedWasChecked = true
        } else {
            planned.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
            delegateCell?.plannedChanged(index: indexPath!, bool: false)
            plannedWasChecked = false
            listitem.text = listitem.text!
        }
    }
    // MARK: - Initialization
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
