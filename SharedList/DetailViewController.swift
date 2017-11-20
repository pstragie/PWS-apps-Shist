//
//  DetailViewController.swift
//  SharedList
//
//  Created by Pieter Stragier on 05/11/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class DetailViewController: UIViewController {
    
    // MARK: - variables and constants
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let coreDelegate = CoreDataManager(modelName: "dataModel")
    
    weak var personalItem:Personal?
    weak var sharedItem:Shared?
    var entity: String?
    var listname: String?
    var headers: Array<String> = []
    var planned: Bool?
    var done: Bool?
    var originalReminderDate: Date?
    var newReminderSet: Bool?
    var newReminderDate: Date?
    var tempStoredDate: Date?
    var itemInfo: String?
    var itemName: String?
    var viewPickerViewReminder = UIView()
    var pickerViewReminder: UIDatePicker!
    var pickerViewReminderDone: UIButton!
    var pickerViewReminderCancel: UIButton!
    var chosenDateTime: Date?
    var originalDueDate: Date?
    var newDueDate: Date?
    var duedateSet: Bool?
    
    // MARK: - IBOutlets
    @IBOutlet weak var itemTitle: UILabel!
    @IBOutlet weak var editItemTitle: UITextField!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var editItemInfo: UITextView!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var moveToSharedButton: UIButton!
    @IBOutlet weak var delButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var dueDateCheckBoxButton: UIButton!
    @IBOutlet weak var plannedButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var pickerTextField: UITextField!

    @IBOutlet weak var showPickerReminder: UIButton!
    @IBOutlet weak var segmentedYesNo: UISegmentedControl!
    // MARK: - IBActions
    
    @IBAction func imageButtonTapped(_ sender: UIButton) {
    }
    @IBAction func showPickerReminderTapped(_ sender: UIButton) {
        if viewPickerViewReminder.isHidden == false {
            showPickerReminder.setTitle("Show", for: .normal)
            viewPickerViewReminder.isHidden = true
        } else {
            showPickerReminder.setTitle("Hide", for: .normal)
            self.viewPickerViewReminder.isHidden = false
        }
    }
    @IBAction func segmentedYesNoChanged(_ sender: UISegmentedControl) {
        // To Yes: popup DatePicker + Set reminderSet = true
        if segmentedYesNo.selectedSegmentIndex == 1 {
            // Pop up datePicker
            self.saveButton.isEnabled = false
            self.viewPickerViewReminder.isHidden = false
            // Set reminderSet = true
            if entity == "personal" {
                personalItem?.reminderSet = true
            } else {
                sharedItem?.reminderSet = true
            }
        } else {
        // To No: Set reminderSet = false
            self.saveButton.isEnabled = true
            if entity == "personal" {
                personalItem?.reminderSet = false
            } else {
                sharedItem?.reminderSet = false
            }
            showPickerReminder.isHidden = true
            self.viewPickerViewReminder.isHidden = true
        }
        
    }
    @IBAction func delTapped(_ sender: UIButton) {
        delButton.setImage(#imageLiteral(resourceName: "bin"), for: .normal)
        delButton.setImage(#imageLiteral(resourceName: "bin_open"), for: .highlighted)
        
        //dismiss(animated: true, completion: nil)
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
        if entity == "personal" {
            personalItem?.planned = planned!
            personalItem?.done = done!
            if editItemInfo.text != "" {
                personalItem?.iteminfo = editItemInfo.text!
            }
            if editItemTitle.text != "" {
                personalItem?.item = editItemTitle.text!
            }
            personalItem?.header = pickerTextField.text
            personalItem?.duedateSet = duedateSet!
            if dueDateCheckBoxButton.currentImage == #imageLiteral(resourceName: "checkbox-filled") {
                if newDueDate != nil {
                    personalItem?.duedate = newDueDate! as NSDate
                } else {
                    personalItem?.duedate = originalDueDate! as NSDate
                }
            } else {
                personalItem?.duedate = nil
            }
            if segmentedYesNo.selectedSegmentIndex == 1 {
                if newReminderDate != nil {
                    personalItem?.reminderDate = newReminderDate! as NSDate
                }
            }
            personalItem?.reminderSet = newReminderSet!
        } else {
            sharedItem?.planned = planned!
            sharedItem?.done = done!
            if editItemInfo.text != "" {
                sharedItem?.iteminfo = editItemInfo.text!
            }
            if editItemTitle.text != "" {
                sharedItem?.item = editItemTitle.text!
            }
            sharedItem?.header = pickerTextField.text
            sharedItem?.duedateSet = duedateSet!
            if dueDateCheckBoxButton.currentImage == #imageLiteral(resourceName: "checkbox-filled") {
                if newDueDate != nil {
                    sharedItem?.duedate = newDueDate! as NSDate
                } else {
                    sharedItem?.duedate = originalDueDate! as NSDate
                }
            } else {
                sharedItem?.duedate = nil
            }
            if segmentedYesNo.selectedSegmentIndex == 1 {
                if newReminderDate != nil {
                    sharedItem?.reminderDate = newReminderDate! as NSDate
                }
            }
            sharedItem?.reminderSet = newReminderSet!
        }
        coreDelegate.saveContext()
    }
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
    }
    @IBAction func dueDateCheckBoxButtonTapped(_ sender: UIButton) {
        if dueDateCheckBoxButton.currentImage == #imageLiteral(resourceName: "checkbox-empty") {
            dueDateCheckBoxButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
            dueDatePicker.tintColor = UIColor.Palette.greenVar3
            duedateSet = true
        } else {
            dueDateCheckBoxButton.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
            dueDatePicker.tintColor = UIColor.gray
            duedateSet = false
        }
    }
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        insertData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if segmentedYesNo.selectedSegmentIndex == 1 {
            showPickerReminder.isHidden = false
        } else {
            showPickerReminder.isHidden = true
        }
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if viewPickerViewReminder.isHidden == true {
            self.showPickerReminder.setTitle("Show", for: .normal)
            self.saveButton.isEnabled = true
        } else {
            self.showPickerReminder.setTitle("Hide", for: .normal)
            self.saveButton.isEnabled = false
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }

    // MARK: - Functions
    func setupLayout() {
        editItemInfo.layer.borderColor = UIColor.lightGray.cgColor
        editItemInfo.layer.borderWidth = 1
        editItemTitle.addTarget(self, action: #selector(editItemTitleDidEndEditing(_:)), for: .editingDidEnd)
    }
    
    func insertData() {
        let listName = listname!
        
        //headers = coreDelegate.getHeaderArray("Personal", listname: listName!)
        print("insertData, listname = \(listName)")
        var headerArray: Array<String> = []
        let moc = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity!.capitalized)
        request.resultType = .dictionaryResultType
        request.predicate = NSPredicate(format: "lists.listname == %@", listName)
        request.propertiesToFetch = ["header"]
        request.returnsDistinctResults = true
        
        do {
            let result = try moc.fetch(request)
            let resultsDict = result as! [[String: String]]
            for r in resultsDict {
                headerArray.append(r["header"]!)
            }
        } catch {
            print("error fetching: \(error.localizedDescription)")
        }
        headers = headerArray
        if entity == "personal" {
            let hIndex = headers.index(of: (personalItem?.header)!)
            let headerToMove = headers.remove(at: hIndex!)
            headers.insert(headerToMove, at: 0)
            itemTitle.text = personalItem?.item
            editItemInfo.text = personalItem?.iteminfo
            pickerTextField.loadDropdownData(data: headers)
            if personalItem?.planned == true {
                planned = true
                plannedButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
            } else {
                planned = false
                plannedButton.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
            }
            if personalItem?.done == true {
                done = true
                doneButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
            } else {
                done = false
                doneButton.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
            }
            if personalItem?.reminderSet == true {
                segmentedYesNo.selectedSegmentIndex = 1
                showPickerReminder.isHidden = false
            } else {
                segmentedYesNo.selectedSegmentIndex = 0
                showPickerReminder.isHidden = true
            }
            if personalItem?.reminderDate != nil {
                originalReminderDate = personalItem?.reminderDate as Date?
            } else {
                if personalItem?.duedate == nil {
                    originalReminderDate = Date()
                    dueDateCheckBoxButton.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
                } else {
                    originalReminderDate = personalItem?.duedate as Date?
                    dueDateCheckBoxButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
                }
            }
            newReminderSet = personalItem?.reminderSet
            setupViewReminderDatePicker()
            self.pickerViewReminder.addTarget(self, action: #selector(reminderPickerChanged), for: .valueChanged)
            if personalItem?.duedate != nil {
                originalDueDate = personalItem?.duedate as Date?
            } else {
                originalDueDate = Date()
            }
            if personalItem?.duedateSet == true {
                duedateSet = true
            } else {
                duedateSet = false
            }
            if originalDueDate != nil {
                dueDatePicker.layer.borderColor = UIColor.Palette.greenVar3.cgColor
                dueDatePicker.layer.borderWidth = 1
                dueDatePicker.setDate(originalDueDate!, animated: true)
            } else {
                dueDatePicker.layer.borderWidth = 0
                dueDatePicker.setDate(Date(), animated: false)
            }
            self.dueDatePicker.addTarget(self, action: #selector(dueDatePickerChanged), for: .valueChanged)
        } else {
            let hIndex = headers.index(of: (sharedItem?.header)!)
            let headerToMove = headers.remove(at: hIndex!)
            headers.insert(headerToMove, at: 0)
            itemTitle.text = sharedItem?.item
            editItemInfo.text = sharedItem?.iteminfo
            pickerTextField.loadDropdownData(data: headers)
            if sharedItem?.planned == true {
                planned = true
                plannedButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
            } else {
                planned = false
                plannedButton.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
            }
            if sharedItem?.done == true {
                done = true
                doneButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
            } else {
                done = false
                doneButton.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
            }
            if sharedItem?.reminderSet == true {
                segmentedYesNo.selectedSegmentIndex = 1
                showPickerReminder.isHidden = false
            } else {
                segmentedYesNo.selectedSegmentIndex = 0
                showPickerReminder.isHidden = true
            }
            if sharedItem?.reminderDate != nil {
                originalReminderDate = sharedItem?.reminderDate as Date?
            } else {
                if sharedItem?.duedate == nil {
                    originalReminderDate = Date()
                    dueDateCheckBoxButton.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
                } else {
                    originalReminderDate = sharedItem?.duedate as Date?
                    dueDateCheckBoxButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
                }
            }
            newReminderSet = sharedItem?.reminderSet
            setupViewReminderDatePicker()
            self.pickerViewReminder.addTarget(self, action: #selector(reminderPickerChanged), for: .valueChanged)
            if sharedItem?.duedate != nil {
                originalDueDate = sharedItem?.duedate as Date?
            } else {
                originalDueDate = Date()
            }
            if sharedItem?.duedateSet == true {
                duedateSet = true
            } else {
                duedateSet = false
            }
            if originalDueDate != nil {
                dueDatePicker.layer.borderColor = UIColor.Palette.greenVar3.cgColor
                dueDatePicker.layer.borderWidth = 1
                dueDatePicker.setDate(originalDueDate!, animated: true)
            } else {
                dueDatePicker.layer.borderWidth = 0
                dueDatePicker.setDate(Date(), animated: false)
            }
            self.dueDatePicker.addTarget(self, action: #selector(dueDatePickerChanged), for: .valueChanged)
        }
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
    
    // MARK: Reminder date Picker
    func setupViewReminderDatePicker() {
        print("setting up viewReminder")
        self.viewPickerViewReminder.isHidden = true
        self.viewPickerViewReminder.translatesAutoresizingMaskIntoConstraints = false
        self.viewPickerViewReminder=UIView(frame:CGRect(x: 0, y: 30, width: self.view.bounds.width, height: 215))
        self.view.addSubview(viewPickerViewReminder)
        self.pickerViewReminder=UIDatePicker(frame:CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 160))
        viewPickerViewReminder.layer.backgroundColor = UIColor.Palette.blueVar3.cgColor
        pickerViewReminder.datePickerMode = .dateAndTime
        
        if originalReminderDate != nil {
            self.pickerViewReminder.setDate(originalReminderDate!, animated: false)
        } else {
            if entity == "personal" {
                if personalItem?.duedate == nil {
                    self.pickerViewReminder.setDate(Date(), animated: true)
                } else {
                    self.pickerViewReminder.setDate((personalItem?.duedate)! as Date, animated: true)
                }
            } else {
                if sharedItem?.duedate == nil {
                    self.pickerViewReminder.setDate(Date(), animated: true)
                } else {
                    self.pickerViewReminder.setDate((sharedItem?.duedate)! as Date, animated: true)
                }

            }
        }
        
        let doneButton = UIButton()
        doneButton.setTitle("Save", for: .normal)
        doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        doneButton.setTitleColor(.blue, for: .normal)
        doneButton.setTitleColor(.red, for: .highlighted)
        doneButton.backgroundColor = .white
        doneButton.layer.cornerRadius = 8
        doneButton.layer.borderWidth = 1
        doneButton.layer.borderColor = UIColor.gray.cgColor
        doneButton.showsTouchWhenHighlighted = true
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        let cancelButton = UIButton()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        cancelButton.setTitleColor(.blue, for: .normal)
        cancelButton.setTitleColor(.red, for: .highlighted)
        cancelButton.backgroundColor = .white
        cancelButton.layer.cornerRadius = 8
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor.gray.cgColor
        cancelButton.showsTouchWhenHighlighted = true
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        let buttonStack = UIStackView(arrangedSubviews: [doneButton, cancelButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.alignment = .fill
        buttonStack.spacing = 0
        buttonStack.translatesAutoresizingMaskIntoConstraints = true
        doneButton.addTarget(self, action: #selector(reminderDoneTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(reminderCancelTapped), for: .touchUpInside)
        
        let verStack = UIStackView(arrangedSubviews: [pickerViewReminder, buttonStack])
        verStack.axis = .vertical
        verStack.distribution = .fillProportionally
        verStack.alignment = .fill
        verStack.spacing = 5
        verStack.translatesAutoresizingMaskIntoConstraints = false
        self.viewPickerViewReminder.addSubview(verStack)
        //Stackview Layout
        let viewsDictionary = ["stackView": verStack]
        let stackView_H = NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[stackView]-10-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let stackView_V = NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[stackView]-8-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        viewPickerViewReminder.addConstraints(stackView_H)
        viewPickerViewReminder.addConstraints(stackView_V)
        self.viewPickerViewReminder.isHidden = true
    }
    
    func reminderPickerChanged() {
        chosenDateTime = self.pickerViewReminder.date
    }
    
    func dueDatePickerChanged() {
        newDueDate = self.dueDatePicker.date
        dueDatePicker.layer.borderColor = UIColor.Palette.greenVar3.cgColor
        dueDatePicker.layer.borderWidth = 1
        dueDateCheckBoxButton.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
        duedateSet = true
    }
    
    func reminderDoneTapped() {
        showPickerReminder.setTitle("Show", for: .normal)
        showPickerReminder.isHidden = false
        self.viewPickerViewReminder.isHidden = true
        newReminderSet = true
        if chosenDateTime != nil {
            newReminderDate = chosenDateTime!
            if newReminderDate != nil {
                tempStoredDate = newReminderDate!
            }
        } else {
            if tempStoredDate == nil {
                newReminderDate = originalReminderDate!
            } else {
                newReminderDate = tempStoredDate!
            }
        }
        saveButton.isEnabled = true
    }
    
    func reminderCancelTapped() {
        self.saveButton.isEnabled = true
        self.viewPickerViewReminder.isHidden = true
        if sharedItem?.reminderSet == true {
            showPickerReminder.setTitle("Show", for: .normal)
            segmentedYesNo.selectedSegmentIndex = 1
            showPickerReminder.isHidden = false
        } else {
            segmentedYesNo.selectedSegmentIndex = 0
            showPickerReminder.isHidden = true
        }
        newReminderSet = false
        if newReminderDate == nil {
            self.pickerViewReminder.setDate(originalReminderDate!, animated: true)
        } else {
            self.pickerViewReminder.setDate(newReminderDate!, animated: true)
        }
    }
    
    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "segueToImage":
            let destination = segue.destination as! ImageViewController
            if entity == "personal" {
                destination.objectPersonal = personalItem
                destination.entity = "personal"
            } else {
                destination.objectShared = sharedItem
                destination.entity = "shared"
            }
        default:
            break
        }
        
    }
    @IBAction func saveImageUnwindAction(unwindSegue: UIStoryboardSegue) {
        
    }
    
    @IBAction func cancelImageUnwindAction(unwindSegue: UIStoryboardSegue) {
    }
    
}

extension UITextField {
    func loadDropdownData(data: [String]) {
        self.inputView = MyPickerView(pickerData: data, dropdownField: self)
    }
    
}
