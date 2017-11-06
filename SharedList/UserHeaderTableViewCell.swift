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
}

class UserHeaderTableViewCell: UITableViewCell {
    weak var delegate: UserHeaderTableViewCellDelegate?
    
    static let reuseIdentifier = "UserHeader"
    var delegateCell: PersonalListsViewController?
    var indexPath: IndexPath?
    
    @IBOutlet weak var delButton: UIButton!
    @IBAction func delButton(_ sender: UIButton) {
        delButton.setImage(#imageLiteral(resourceName: "bin"), for: .normal)
        delButton.setImage(#imageLiteral(resourceName: "bin_open"), for: .highlighted)
        delegate?.didTapBinHeader(sender: self)
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
            delButton.isHidden = false
        } else {
            delButton.isHidden = true
        }
        
    }
    
    @IBAction func selectedHeader(sender: AnyObject) {
        delegate?.didSelectUserHeaderTableViewCell(sender: self, Selected: true)        
    }
}
