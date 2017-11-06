//
//  MyPickerView.swift
//  SharedList
//
//  Created by Pieter Stragier on 06/11/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import Foundation
import UIKit

class MyPickerView: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {
    var pickerData: [String]!
    var pickerTextField: UITextField!
    var selected: Int!
    
    init(pickerData: [String], dropdownField: UITextField, selected: Int) {
        super.init(frame: CGRect.zero)
        
        self.pickerData = pickerData
        self.pickerTextField = dropdownField
        self.selected = selected
        
        self.delegate = self
        self.dataSource = self
        
        DispatchQueue.main.async(execute: {
            if pickerData.count != 0 {
                self.pickerTextField.text = self.pickerData[selected]
                self.pickerTextField.isEnabled = true
            } else {
                self.pickerTextField.text = nil
                self.pickerTextField.isEnabled = false
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Sets number of columns in picker view
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    override func selectedRow(inComponent component: Int) -> Int {
        return selected
    }
    // Sets number of rows in the picker view
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // This function sets the text of the picker view to the content of the "headers" array
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    // When user selects an option, this function will set the text of the textfield to reflect
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerTextField.text = pickerData[row]
    }
    
    
}
