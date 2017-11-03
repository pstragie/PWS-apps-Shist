//
//  UserHeaderTableViewCell
//  SharedList
//
//  Created by Pieter Stragier on 30/10/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit


protocol UserHeaderTableViewCellDelegate {
    func didSelectUserHeaderTableViewCell(Selected: Bool, UserHeader: UserHeaderTableViewCell)
}

class UserHeaderTableViewCell: UITableViewCell {
    var delegate: UserHeaderTableViewCellDelegate?
    
    var headerCellSection:Int?
    
    static let reuseIdentifier = "UserHeader"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func selectedHeader(sender: AnyObject) {
        delegate?.didSelectUserHeaderTableViewCell(Selected: true, UserHeader: self)
        print("Cell Selected")
        // Set button frame
        let frame: CGRect = sender.frame
        let delButton: UIButton = UIButton(frame: CGRect(x: frame.size.width - 25, y: 10, width: 20, height: 20))
        delButton.setTitle("-", for: .normal)
        delButton.backgroundColor = UIColor.red
        delButton.layer.cornerRadius = 10
        sender.addSubview(delButton)
        (sender as! UIButton).tintColor = UIColor.darkGray
        delButton.isHidden = false
    }
    
    @IBAction func notSelectedHeader(sender: AnyObject) {
        delegate?.didSelectUserHeaderTableViewCell(Selected: false, UserHeader: self)
        (sender as! UIButton).tintColor = UIColor.lightGray
    }
}
