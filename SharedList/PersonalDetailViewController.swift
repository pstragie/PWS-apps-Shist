//
//  PersonalDetailViewController.swift
//  SharedList
//
//  Created by Pieter Stragier on 05/11/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import Foundation
import UIKit

class PersonalDetailViewController: UIViewController {
    
    let coreDelegate = CoreDataManager(modelName: "dataModel")

    weak var item: Personal?
    var planned: Bool?
    var done: Bool?
    var itemInfo: String?
    var itemDueDate: Date?
    var itemName: String?
    
    var headers: Array<String> = []
    @IBOutlet weak var itemTitle: UILabel!
    @IBOutlet weak var editItemTitle: UITextField!
    @IBOutlet weak var editItemInfo: UITextView!
    @IBOutlet weak var dueDate: UIDatePicker!
    @IBOutlet weak var moveToSharedButton: UIButton!
    @IBOutlet weak var delButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var plannedButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBAction func delTapped(_ sender: UIButton) {
        delButton.setImage(#imageLiteral(resourceName: "bin"), for: .normal)
        delButton.setImage(#imageLiteral(resourceName: "bin_open"), for: .highlighted)
        
        dismiss(animated: true, completion: nil)
    }
    @IBAction func doneTapped(_ sender: UIButton) {
        if doneButton.image(for: .normal) == #imageLiteral(resourceName: "checkbox-empty") {
            done = true
            doneButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
        } else {
            done = false
            doneButton.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
        }
    }
    @IBOutlet weak var pickerTextField: UITextField!
    @IBAction func plannedTapped(_ sender: UIButton) {
        if plannedButton.image(for: .normal) == #imageLiteral(resourceName: "checkbox-empty") {
            planned = true
            plannedButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
        } else {
            planned = false
            plannedButton.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
        }
    }
    @IBAction func editItemTitle(_ sender: UITextField) {
    }
    @IBAction func moveToSharedButton(_ sender: UIButton) {
    }
   
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        item?.planned = planned!
        item?.done = done!
        if editItemInfo.text != "" {
            item?.iteminfo = editItemInfo.text!
        }
        if editItemTitle.text != "" {
            item?.item = editItemTitle.text!
        }
        item?.header = pickerTextField.text
        //item?.duedate = itemDueDate! as NSDate
        coreDelegate.saveContext()
        //performSegue(withIdentifier: "unwindSegueToPersonalListView", sender: self)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
    }
    
    
    override func viewDidLoad() {
        setupLayout()
        insertData()
    }
    
    func insertData() {
        headers = coreDelegate.getHeaderArray("Personal").sorted()
        itemTitle.text = item?.item
        editItemInfo.text = item?.iteminfo
        let row = headers.index(of: (item?.header)!)
        pickerTextField.loadDropdownData(data: headers, selected: row!)
        if item?.planned == true {
            planned = true
            plannedButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
        } else {
            planned = false
            plannedButton.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
        }
        if item?.done == true {
            done = true
            doneButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
        } else {
            done = false
            doneButton.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
        }
        
    }
    func setupLayout() {
        editItemInfo.layer.borderColor = UIColor.lightGray.cgColor
        editItemInfo.layer.borderWidth = 1
        
        editItemTitle.addTarget(self, action: #selector(editItemTitleDidEndEditing(_:)), for: .editingDidEnd)
    }
    
    func editItemTitleDidEndEditing(_ textView: UITextView) {
        if editItemTitle.text == itemTitle.text || editItemTitle.text == "" {
            itemTitle.text = itemTitle.text
        } else {
            let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: itemTitle.text!)
            attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, attributeString.length))
            attributeString.addAttribute(NSStrikethroughColorAttributeName, value: UIColor.darkGray, range: NSMakeRange(0, attributeString.length))
            itemTitle.attributedText = attributeString
        } 
    }
}
extension UITextField {
    func loadDropdownData(data: [String], selected: Int) {
        self.inputView = MyPickerView(pickerData: data, dropdownField: self, selected: selected)
    }
}
