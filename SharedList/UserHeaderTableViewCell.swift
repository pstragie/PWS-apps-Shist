//
//  UserHeaderTableViewCell
//  SharedList
//
//  Created by Pieter Stragier on 30/10/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit
import Foundation

protocol UserHeaderTableViewCellDelegate: class {
    func didSelectUserHeaderTableViewCell(sender: UserHeaderTableViewCell, Selected: Bool)
    func didTapBinHeader(sender: UserHeaderTableViewCell)
    func didTapEditIcon(sender: UserHeaderTableViewCell)
}

class UserHeaderTableViewCell: UITableViewCell {
    weak var delegate: UserHeaderTableViewCellDelegate?
    
    @IBOutlet weak var invisibleButton: UIButton!
    @IBOutlet weak var userHeaderView: UIView!
    static let reuseIdentifier = "UserHeader"
    var delegateCell: PersonalListsViewController?
    var indexPath: IndexPath?
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var delButton: UIButton!
    @IBAction func delButton(_ sender: UIButton) {
        delButton.setImage(#imageLiteral(resourceName: "bin"), for: .normal)
        delButton.setImage(#imageLiteral(resourceName: "bin_open"), for: .highlighted)
        delegate?.didTapBinHeader(sender: self)
    }
    
    @IBAction func editTapped(_ sender: UIButton) {
        print("UHTVC: edit tapped")
        delegate?.didTapEditIcon(sender: self)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        print("set selected")
        // Configure the view for the selected state
        if selected == true {
            userHeaderView.layer.backgroundColor = UIColor.Palette.blueVar3.cgColor
            editButton.isHidden = false
            delButton.isHidden = false
            //self.sendSubview(toBack: invisibleButton)
        } else {
            userHeaderView.layer.backgroundColor = UIColor.Palette.blueVar1.cgColor
            editButton.isHidden = true
            delButton.isHidden = true
            //self.bringSubview(toFront: invisibleButton)
        }
        
    }
    
    @IBAction func selectedHeader(sender: UIButton) {
        delegate?.didSelectUserHeaderTableViewCell(sender: self, Selected: true)        
    }
}
