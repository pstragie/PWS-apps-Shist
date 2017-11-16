//
//  ItemListViewController.swift
//  SharedList
//
//  Created by Pieter Stragier on 30/10/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit
import Speech
import CoreData

class ItemListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSpeechRecognizerDelegate {

    // MARK: - Variables and constants
    
    weak var items: Lists? {
        didSet {
            self.configureView()
        }
    }
    var listName: String?
    //let itemListViewController = ItemListViewController()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let coreDelegate = CoreDataManager(modelName: "dataModel")
    let localdata = UserDefaults.standard
    
    var selectedBellIndex: IndexPath?
    var viewPickerViewReminder = UIView()
    var pickerViewReminder: UIDatePicker!
    var originalDateTime: Date?
    var storedReminderDate: Date?
    var newReminderDate: Date?
    var chosenDateTime: Date?
    var moc: NSManagedObjectContext!
    var listop: String = "List"
    var detailIndexPath: IndexPath?
    var previouslySelected: UserHeaderTableViewCell?
    var headerSelected:Bool = false
    var selectedHeaderText:String?
    var textFieldIsEmpty:Bool = true
    var segAttr = NSDictionary(object: UIFont(name: "Helvetica", size: 20.0)!, forKey: NSFontAttributeName as NSCopying)
    var latestaddedHeader: String = ""
    var changeHeaderView = UIView()
    var sectionTitle: String?
    var newSectionTitle: String?
    var duedateSet: Bool?
    var dueDateGradient: CAGradientLayer!
    
    // MARK: - IBOutlets
    @IBOutlet weak var pageTitle: UINavigationItem!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var spokenTextView: UITextView!
    @IBOutlet weak var subview: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputview: UIView!
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var addHeader: UIButton!
    @IBOutlet weak var addItem: UIButton!

    @IBOutlet weak var tableItemView: UIView!
    @IBOutlet weak var userHeaderView: UIView!
            
    // MARK: - IBActions
    
    

    @IBAction func addHeader(_ sender: UIButton) {
        // Input
        //let item = Personal(context: moc)
        addNewHeader()
    }
    @IBAction func addItem(_ sender: UIButton) {
        // Input
        addNewItem()
    }
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        // Do any additional setup after loading the view, typically from a nib.
        moc = appDelegate.persistentContainer.viewContext
        self.updateView()
        setupLayout()
        allowSpeech()
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("items: \(String(describing: items?.personal))")
        listName = items?.listname!
        tableView.reloadData()
        input.becomeFirstResponder()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateView()
        
        if input.text == "" {
            addHeader.isEnabled = false
            addItem.isEnabled = false
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Functions
    func setupLayout() {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        input.layer.cornerRadius = 10
        addHeader.titleLabel?.text = "+H"
        input.addTarget(self, action: #selector(textFielddidChange(_:)), for: .editingChanged)
        input.layer.borderColor = UIColor.Palette.brownVar4.cgColor
        inputview.layer.backgroundColor = UIColor.Palette.brownVar3.cgColor
        input.layer.borderWidth = 2
        createGradient()
        
        if items?.personal?.value(forKey: "reminderDate") != nil {
            originalDateTime = items?.personal?.value(forKey: "reminderDate") as? Date
        } else {
            if items?.personal?.value(forKey: "duedate") == nil {
                originalDateTime = Date()
            } else {
                originalDateTime = items?.personal?.value(forKey: "duedate") as? Date
            }
        }
        duedateSet = items?.personal?.value(forKey: "duedateSet") as? Bool
        setupViewReminderDatePicker()
        setupChangeHeaderField()
        self.pickerViewReminder.addTarget(self, action: #selector(reminderPickerChanged), for: .valueChanged)
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let item = self.items {
            if let label = self.pageTitle {
                label.title = item.listname
            }
        }
    }
    
    func addNewHeader() {
        if (input.text != "") {
            let personalItem = Personal(context: moc)
            personalItem.setValue(input.text!, forKey: "header")
            personalItem.setValue("", forKey: "item")
            items?.addToPersonal(personalItem)
            
            headerSelected = false
            latestaddedHeader = input.text!
            coreDelegate.saveContext()
            performTheFetch()
            input.text = ""
            tableView.reloadData()
        } else {
            // Nothing
        }
    }
    
    func addNewItem() {
        //let item = Personal(context: moc)
        var header: String = ""
        if (input.text != "") { // Nothing happens when field is empty
            let personalItem = Personal(context: moc)
            personalItem.setValue(input.text!, forKey: "item")
            personalItem.setValue(Date() as NSDate, forKey: "createdAt")
            personalItem.setValue(false, forKey: "planned")
            personalItem.setValue(false, forKey: "done")
            
            if headerSelected == false {
                print("header not selected")
                if latestaddedHeader != "" { // Add item to last added header
                    header = latestaddedHeader
                } else { // No header added
                    header = "Section 1"
                }
            } else { // headerSelected == true
                header = selectedHeaderText!
            }
            personalItem.setValue(header, forKey: "header")
            items?.addToPersonal(personalItem)
            // Check if the section was empty (item == "") e.g. when a new section is added
            if itemIsEmpty(header: header) == true {
                // Remove the empty item
                deleteWithPredicate(header: header, item: "")
            }
            input.text = ""
            coreDelegate.saveContext()
            performTheFetch()
            tableView.reloadData()
        } else {
            // Nothing
        }
    }
    
    func plannedChanged(index: IndexPath, bool: Bool) {
        let personalItem = coreDelegate.fetchedResultsControllerPersonal.object(at: index)
        //let personalItem = Personal(context: moc)
        personalItem.setValue(bool, forKey: "planned")
        coreDelegate.saveContext()
    }
    
    func doneChanged(index: IndexPath, bool: Bool) {
        let personalItem = coreDelegate.fetchedResultsControllerPersonal.object(at: index)
        //let personalItem = Personal(context: moc)
        personalItem.setValue(bool, forKey: "done")
        coreDelegate.saveContext()
    }
    
    // MARK: Reminder
    func didTapBellButton(index: IndexPath) {
        // Show datePicker with buttons: remove, save, cancel
        let personalItem = coreDelegate.fetchedResultsControllerPersonal.object(at: index)
        selectedBellIndex = index
        originalDateTime = personalItem.reminderDate! as Date?
        self.pickerViewReminder.setDate(originalDateTime!, animated: true)
        viewPickerViewReminder.isHidden = false
    }
    
    // MARK: Reminder date Picker
    func setupViewReminderDatePicker() {
        print("setup view reminder")
        self.viewPickerViewReminder.isHidden = true
        self.viewPickerViewReminder.translatesAutoresizingMaskIntoConstraints = false
        self.viewPickerViewReminder=UIView(frame:CGRect(x: 0, y: 30, width: self.view.bounds.width, height: 215))
        self.view.addSubview(viewPickerViewReminder)
        self.pickerViewReminder=UIDatePicker(frame:CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 160))
        viewPickerViewReminder.layer.backgroundColor = UIColor.Palette.blueVar3.cgColor
        pickerViewReminder.datePickerMode = .dateAndTime
        
        if originalDateTime != nil {
            self.pickerViewReminder.setDate(originalDateTime!, animated: true)
        } else {
            // Not necessary: bellButton should be invisible
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
        let removeButton = UIButton()
        removeButton.setTitle("Remove", for: .normal)
        removeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        removeButton.setTitleColor(.blue, for: .normal)
        removeButton.setTitleColor(.red, for: .highlighted)
        removeButton.backgroundColor = .white
        removeButton.layer.cornerRadius = 8
        removeButton.layer.borderWidth = 1
        removeButton.layer.borderColor = UIColor.gray.cgColor
        removeButton.showsTouchWhenHighlighted = true
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        let buttonStack = UIStackView(arrangedSubviews: [removeButton, doneButton, cancelButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.alignment = .fill
        buttonStack.translatesAutoresizingMaskIntoConstraints = true
        removeButton.addTarget(self, action: #selector(reminderRemoveTapped), for: .touchUpInside)
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
    func reminderDoneTapped() {
        self.viewPickerViewReminder.isHidden = true
        let personalitem = coreDelegate.fetchedResultsControllerPersonal.object(at: selectedBellIndex!)

        if chosenDateTime != nil {
            newReminderDate = chosenDateTime!
            if newReminderDate != nil {
                storedReminderDate = newReminderDate!
            }
        } else {
            if storedReminderDate == nil {
                newReminderDate = originalDateTime!
            } else {
                newReminderDate = storedReminderDate!
            }
        }
        if newReminderDate != nil {
        personalitem.setValue(newReminderDate!, forKey: "reminderDate")
        } else {
            if storedReminderDate != nil {
                items?.personal?.setValue(storedReminderDate!, forKey: "reminderDate")
            } else {
                items?.personal?.setValue(originalDateTime!, forKey: "reminderDate")
            }
        }
        coreDelegate.saveContext()
    }
    
    func reminderCancelTapped() {
        self.viewPickerViewReminder.isHidden = true
        if newReminderDate != nil {
            self.pickerViewReminder.setDate(newReminderDate!, animated: true)
        } else {
            if originalDateTime != nil {
                self.pickerViewReminder.setDate(originalDateTime!, animated: true)
            } else {
                storedReminderDate = items?.personal?.value(forKey: "reminderDate") as? Date
                if storedReminderDate != nil {
                    self.pickerViewReminder.setDate(storedReminderDate!, animated: true)
                }
                
            }
        }
    }
    
    func reminderRemoveTapped() {
        self.viewPickerViewReminder.isHidden = true
        let personalitem = coreDelegate.fetchedResultsControllerPersonal.object(at: selectedBellIndex!)
        personalitem.setValue(false, forKey: "reminderSet")
        coreDelegate.saveContext()
        tableView.reloadData()
    }

    // MARK: Change header field
    func setupChangeHeaderField() {
        print("setup change header view")
        self.changeHeaderView.isHidden = true
        self.changeHeaderView.translatesAutoresizingMaskIntoConstraints = false
        self.changeHeaderView=UIView(frame: CGRect(x: 0, y: 30, width: self.view.bounds.width, height: 215))
        self.view.addSubview(changeHeaderView)
        self.changeHeaderView.layer.backgroundColor = UIColor.Palette.blueVar3.cgColor

        let headerLabel = UILabel()
        headerLabel.text = "Header"
        headerLabel.textColor = UIColor.white
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let newHeaderTextField = UITextField()
        newHeaderTextField.tintColor = UIColor.Palette.blueVar5
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: newHeaderTextField.bounds.height))
        newHeaderTextField.leftView = paddingView
        newHeaderTextField.leftViewMode = UITextFieldViewMode.always
        newHeaderTextField.backgroundColor = UIColor.white
        newHeaderTextField.placeholder = "Enter new header here"
        newHeaderTextField.layer.borderColor = UIColor.Palette.blueVar5.cgColor
        newHeaderTextField.layer.borderWidth = 2
        newHeaderTextField.layer.cornerRadius = 5
        newHeaderTextField.translatesAutoresizingMaskIntoConstraints = false
        newHeaderTextField.addTarget(self, action: #selector(newHeaderTextFieldChanged(_:)), for: .allEditingEvents)
        
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
        buttonStack.translatesAutoresizingMaskIntoConstraints = true
        doneButton.addTarget(self, action: #selector(saveChangedHeader), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelChangeHeader), for: .touchUpInside)
        
        let verStack = UIStackView(arrangedSubviews: [headerLabel, newHeaderTextField, buttonStack])
        verStack.axis = .vertical
        verStack.distribution = .fillProportionally
        verStack.alignment = .fill
        verStack.spacing = 5
        verStack.translatesAutoresizingMaskIntoConstraints = false
        self.changeHeaderView.addSubview(verStack)
        //Stackview Layout
        let viewsDictionary = ["stackView": verStack]
        let stackView_H = NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[stackView]-10-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let stackView_V = NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[stackView]-8-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        changeHeaderView.addConstraints(stackView_H)
        changeHeaderView.addConstraints(stackView_V)
        self.changeHeaderView.isHidden = true
        
    }
    func newHeaderTextFieldChanged(_ textField: UITextField) {
        newSectionTitle = textField.text!
        
        
    }
    func saveChangedHeader() {
        changeHeaderView.isHidden = true
        input.becomeFirstResponder()
        if newSectionTitle != "" {
            items?.personal?.setValue(newSectionTitle, forKey: "header")
            coreDelegate.saveContext()
            performTheFetch()
            tableView.reloadData()
        }
        
    }
    func cancelChangeHeader() {
        input.becomeFirstResponder()
        changeHeaderView.isHidden = true
    }
    // MARK: - Header behaviour
    func didSelectUserHeaderTableViewCell(sender: UserHeaderTableViewCell, Selected: Bool) {
        print("Header Cell Selected")
        headerSelected = true
        selectedHeaderText = sender.textLabel?.text
        
        if previouslySelected == nil {
            // run once
            previouslySelected = sender
            sender.setSelected(true, animated: true)
        } else {
            // Previously selected header
            previouslySelected?.setSelected(false, animated: true)
            
            // Currently selected header
            sender.setSelected(true, animated: true)
            
            // Set the current header as the previous one
            previouslySelected = sender
        }
    }
    
    func didTapBinHeader(sender: UserHeaderTableViewCell) {
        print("Bin tapped")
        // Delete selected header (and items)
        let sectionTitle = sender.textLabel?.text
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Personal")
        let predicate = NSPredicate(format: "header == %@", sectionTitle!)
        fetchRequest.predicate = predicate
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try moc.execute(batchDeleteRequest)
        } catch {
            print("Batch delete did not work.")
        }
        
        performTheFetch()
        
        tableView.reloadData()
    }
    
    func didTapEditIcon(sender: UserHeaderTableViewCell) {
        print("Edit icon tapped")
        sectionTitle = sender.textLabel?.text
        input.resignFirstResponder()
        self.changeHeaderView.isHidden = false
        
    }

    // MARK: Bin action
    func didTapBinItem(index: IndexPath) {
        print("Bin tapped at: \(index)")
        // Delete selected item from Entity
        let personalitem = coreDelegate.fetchedResultsControllerPersonal.object(at: index as IndexPath)
        let header = personalitem.header!
        let item = personalitem.item!
        deleteWithPredicate(header: header, item: item)
 
        //items?.removeFromPersonal(item)
        //coreDelegate.saveContext()
        latestaddedHeader = header
        performTheFetch()
        // If last item in section is removed, add empty section
        var result: Array<Any> = []
        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "Personal")
        let predicate2 = NSPredicate(format: "header == %@", header)
        fetchRequest2.predicate = predicate2
        do {
            result = try moc.fetch(fetchRequest2)
        } catch {
            print("Fetch did not work.")
        }
        if result.count == 0 {
            print("result = 0")
            let personalitem = Personal(context: moc)
            // Add empty section
            personalitem.header = header
            //item.datum = Date() as NSDate
            //item.planned = false
            //item.done = false
            personalitem.item = ""
            items?.addToPersonal(personalitem)
            headerSelected = false
            do { try moc.save() } catch { print("not saved") }
            coreDelegate.saveContext()
        } else {
            // Do nothing
            print("result is not 0: \(result.count)")
        }
        performTheFetch()
        tableView.reloadData()
    }
    
    // MARK: Other
    func deleteWithPredicate(header: String, item: String) {
        let subpred1 = NSPredicate(format: "header == %@", header)
        let subpred2 = NSPredicate(format: "item == %@", item)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [subpred1, subpred2])
        coreDelegate.fetchedResultsControllerPersonal.fetchRequest.predicate = predicate
        let fetchRequest = coreDelegate.fetchedResultsControllerPersonal.fetchRequest
        if let result = try? moc.fetch(fetchRequest) {
            for object in result {
                moc.delete(object)
            }
        }
    }
    func performTheFetch() {
        do {
            try coreDelegate.fetchedResultsControllerPersonal.performFetch()
        } catch {
            let fetchError = error as NSError
            fatalError("Could not fetch records: \(fetchError)")
        }
    }
    func configure(_ cell: CellModel, at indexPath: IndexPath) {
        // Fetch item
        let item = coreDelegate.fetchedResultsControllerPersonal.object(at: indexPath)
        // Configure cell
        cell.listitem.text = item.item
    }
    func textFielddidChange(_ textField: UITextField) {
        if input.text == "" {
            textFieldIsEmpty = true
        } else {
            textFieldIsEmpty = false
        }
        
        if textFieldIsEmpty == false {
            addItem.isEnabled = true
            addHeader.isEnabled = true
        } else {
            addItem.isEnabled = false
            addHeader.isEnabled = false
        }
        
    }
    func itemIsEmpty(header: String) -> Bool {
        var itemIsEmpty: Bool = false
        var result: Array<Any> = []
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Personal")
        let subpredicate1 = NSPredicate(format: "item == %@", "")
        let subpredicate2 = NSPredicate(format: "header == %@", header)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [subpredicate1, subpredicate2])
        fetchRequest.predicate = predicate
        do {
            result = try moc.fetch(fetchRequest)
            
        } catch {
            print("Fetch did not work.")
        }
        if result.count == 1 {
            itemIsEmpty = true
        } else {
            itemIsEmpty = false
        }
        
        return itemIsEmpty
    }
    
    func createGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.Palette.brownVar5.cgColor, UIColor.Palette.brownVar1.cgColor]
        gradient.locations = [0.0, 0.5]
        self.view.layer.insertSublayer(gradient, at: 0)
        
        let gradientInputView = CAGradientLayer()
        gradientInputView.frame = inputview.bounds
        gradientInputView.colors = [UIColor.black.cgColor, UIColor.brown.cgColor, UIColor.lightGray.cgColor]
        gradientInputView.locations = [0.0, 0.01, 1.0]
        //self.inputview.layer.insertSublayer(gradientInputView, at: 0)
    }
    
    // MARK: - Speech recognition
    @IBOutlet weak var micButton: UIButton!
    @IBAction func micButton(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            micButton.isEnabled = false
            micButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            micButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func allowSpeech() {
        micButton.isEnabled = false
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
        var isButtonEnabled = false
        switch authStatus {
        case .authorized:
            isButtonEnabled = true
        case .denied:
            isButtonEnabled = false
            print("User denied access to speech recognition")
        case .restricted:
            isButtonEnabled = false
            print("Speech recognition restricted on this device")
        case .notDetermined:
            isButtonEnabled = false
            print("Speech recognition not yet authorized")
        }
        OperationQueue.main.addOperation() {
            self.micButton.isEnabled = isButtonEnabled
        }
        }
    }
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest.")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil {
                self.input.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.micButton.isEnabled = true
            }
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        input.text = "Say something, I'm listening!"
        
    }
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            micButton.isEnabled = true
        } else {
            micButton.isEnabled = false
        }
    }
    
    // MARK: - updateView
    func updateView() {
        
    }
    func filterForList(listname:String) {
        print("filter to fill table")
        let subpred1 = NSPredicate(format: "lists.listname != %@", listname)
        let subpred2 = NSPredicate(format: "lists.plist == true")
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [subpred1, subpred2])
        coreDelegate.fetchedResultsControllerPersonal.fetchRequest.predicate = predicate
        
        do {
            try coreDelegate.fetchedResultsControllerPersonal.performFetch()
        } catch {
            fatalError("Could not fetch")
        }
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        if items != nil {
            filterForList(listname:listName!)
        
            guard let sections = coreDelegate.fetchedResultsControllerPersonal.sections else {
                print("no sections found")
                return 0
            }
            print("found sections: \((sections.count))")
            return sections.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let headerCell = tableView.dequeueReusableCell(withIdentifier: "UserHeader") as? UserHeaderTableViewCell else {
            fatalError("found nil")
        }
        if items != nil {
            filterForList(listname:listName!)
        }
        // Get unique headers from core data!
        guard let sectionInfo = coreDelegate.fetchedResultsControllerPersonal.sections?[section] else {
            fatalError("Unexpected section")
        }
        
        headerCell.delegate = self
        headerCell.layoutMargins.left = 30
        headerCell.textLabel?.text = sectionInfo.name
        headerCell.textLabel?.textColor = UIColor.white
        headerCell.delButton.tintColor = UIColor.white
        headerCell.editButton.tintColor = UIColor.white
        headerCell.layer.shadowColor = UIColor.black.cgColor
        headerCell.layer.shadowRadius = 5
        headerCell.layer.shadowOffset = CGSize.zero
        headerCell.layer.shadowOpacity = 0.50
        headerCell.layer.masksToBounds = false
        headerCell.clipsToBounds = false
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Get unique headers from core data
        if items != nil {
            filterForList(listname:listName!)
        
            let count = coreDelegate.fetchedResultsControllerPersonal.sections?[section].numberOfObjects
            
            if items?.personal?.count != 0 {
                
               let header = coreDelegate.getHeaderArray("Personal", listname: (items?.listname)!).sorted()[section]
                if itemIsEmpty(header: header) {
                    return count! - 1
                }
            }
            return count!
        }
        return 0
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellModel.reuseIdentifier, for: indexPath) as? CellModel else {
            fatalError("Unexpected Index Path")
        }
        // Check if due date is imminent
        let item = coreDelegate.fetchedResultsControllerPersonal.object(at: indexPath)
        cell.cellView.layer.borderColor = UIColor.Palette.beigeVar1.cgColor
        cell.cellView.layer.borderWidth = 1
        cell.cellView.layer.cornerRadius = 5
        if  item.duedateSet == true && item.done == false {
            var dueInterval: Double = 0.0
            let dueDate:NSDate = item.duedate!
            dueInterval = dueDate.timeIntervalSinceNow
            if dueInterval <= 86400 {
                cell.cellView.layer.shadowColor = UIColor.purple.cgColor
                cell.cellView.layer.shadowRadius = 6
                cell.cellView.layer.shadowOffset = CGSize.zero
                cell.cellView.layer.shadowOpacity = 0.99
            } else {
                //print("due date not imminent")
            }
        } else {
            //print("due date not set")
        }
        cell.delegateCell = self
        cell.indexPath = indexPath
        // Configure Cell
        cell.selectionStyle = .none
        cell.layer.cornerRadius = 3
        cell.layer.masksToBounds = true
        cell.layer.borderWidth = 0
        cell.showsReorderControl = true
        
        // fetch items for correct header
        //let item = coreDelegate.fetchedResultsControllerPersonal.object(at: indexPath)
        let pl: Bool = item.planned
        let d: Bool = item.done
        if pl == false {
            cell.planned.isEnabled = true
            cell.planned.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
        } else {
            cell.planned.isEnabled = true
            cell.planned.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
        }
        if d == false {
            cell.planned.isEnabled = true
            cell.done.setImage(#imageLiteral(resourceName: "checkbox-empty"), for: .normal)
        } else {
            cell.planned.isEnabled = false
            cell.done.setImage(#imageLiteral(resourceName: "checkbox-filled"), for: .normal)
        }
        cell.listitem?.text = item.item
        if item.iteminfo == "" {
            cell.listinfo.isHidden = true
        } else {
            cell.listinfo.isHidden = false
            cell.listinfo?.text = item.iteminfo
        }
        if item.reminderSet == true {
            var reminderInterval: Double?
            let remDate:NSDate = item.reminderDate!
            reminderInterval = remDate.timeIntervalSinceNow
            if reminderInterval! <= 0.0 {
                cell.bellButton.setImage(#imageLiteral(resourceName: "bell ringing 40x40"), for: .normal)
            } else {
                cell.bellButton.setImage(#imageLiteral(resourceName: "bell 40x40"), for: .normal)
            }
            cell.bellButton.isHidden = false
            
        } else {
            cell.bellButton.isHidden = true
        }
        
        return cell
    }
}

extension ItemListViewController: UserHeaderTableViewCellDelegate, NSFetchedResultsControllerDelegate {
    // MARK: - Controllers
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        print("did change section")
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("an object changed")
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? CellModel {
                configure(cell, at: indexPath)
            }
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        updateView()
    }
    
    
    
    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "segueToDetail":
            let destination = segue.destination as! DetailViewController
            let indexPath = tableView.indexPathForSelectedRow!
            let selectedObject = coreDelegate.fetchedResultsControllerPersonal.object(at: indexPath)
            destination.item = selectedObject
            if items != nil {
                filterForList(listname:listName!)
            }
            let headers = coreDelegate.getHeaderArray("Personal", listname: (items?.listname)!)
            destination.headerlist = headers
            detailIndexPath = indexPath
        default:
            break
        }
     
    }
    @IBAction func saveUnwindAction(unwindSegue: UIStoryboardSegue) {
        performTheFetch()
        tableView.reloadData()

    }
    
    @IBAction func cancelUnwindAction(unwindSegue: UIStoryboardSegue) {
    }
    
    @IBAction func deleteTappedUnwindAction(unwindSegue: UIStoryboardSegue) {
        didTapBinItem(index: detailIndexPath!)
    }
}

extension UIColor {
    // MARK: hex converter (not working?)
    func hexStringToUIColor(hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0, green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0, blue: CGFloat(rgbValue & 0x0000FF) / 255.0, alpha: CGFloat(1.0))
    }
    // MARK: Nested Types
    struct Palette {
        static let brownVar5 = UIColor(red: 127 / 255.0, green: 82 / 255.0, blue: 67 / 255.0, alpha: 1.0)
        static let brownVar4 = UIColor(red: 113 / 255.0, green: 70 / 255.0, blue: 56 / 255.0, alpha: 1.0)
        static let brownVar3 = UIColor(red: 105 / 255.0, green: 61 / 255.0, blue: 48 / 255.0, alpha: 1.0)
        static let brownVar2 = UIColor(red: 97 / 255.0, green: 54 / 255.0, blue: 40 / 255.0, alpha: 1.0)
        static let brownVar1 = UIColor(red: 87 / 255.0, green: 47 / 255.0, blue: 34 / 255.0, alpha: 1.0)
        
        static let beigeVar5 = UIColor(red: 87 / 255.0, green: 57 / 255.0, blue: 34 / 255.0, alpha: 1.0)
        static let beigeVar4 = UIColor(red: 97 / 255.0, green: 65 / 255.0, blue: 40 / 255.0, alpha: 1.0)
        static let beigeVar3 = UIColor(red: 105 / 255.0, green: 73 / 255.0, blue: 48 / 255.0, alpha: 1.0)
        static let beigeVar2 = UIColor(red: 113 / 255.0, green: 81 / 255.0, blue: 56 / 255.0, alpha: 1.0)
        static let beigeVar1 = UIColor(red: 127 / 255.0, green: 93 / 255.0, blue: 67 / 255.0, alpha: 1.0)
        
        static let blueVar5 = UIColor(red: 21 / 255.0, green: 54 / 255.0, blue: 51 / 255.0, alpha: 1.0)
        static let blueVar4 = UIColor(red: 25 / 255.0, green: 59 / 255.0, blue: 57 / 255.0, alpha: 1.0)
        static let blueVar3 = UIColor(red: 29 / 255.0, green: 68 / 255.0, blue: 62 / 255.0, alpha: 1.0)
        static let blueVar2 = UIColor(red: 34 / 255.0, green: 70 / 255.0, blue: 67 / 255.0, alpha: 1.0)
        static let blueVar1 = UIColor(red: 41 / 255.0, green: 78 / 255.0, blue: 75 / 255.0, alpha: 1.0)
        
        static let greenVar5 = UIColor(red: 24 / 255.0, green: 61 / 255.0, blue: 42 / 255.0, alpha: 1.0)
        static let greenVar4 = UIColor(red: 28 / 255.0, green: 68 / 255.0, blue: 48 / 255.0, alpha: 1.0)
        static let greenVar3 = UIColor(red: 33 / 255.0, green: 74 / 255.0, blue: 53 / 255.0, alpha: 1.0)
        static let greenVar2 = UIColor(red: 39 / 255.0, green: 79 / 255.0, blue: 59 / 255.0, alpha: 1.0)
        static let greenVar1 = UIColor(red: 47 / 255.0, green: 89 / 255.0, blue: 68 / 255.0, alpha: 1.0)
        
    }
    
    
}



// MARK: - UISplitViewControllerDelegate
extension ItemListViewController: UISplitViewControllerDelegate {
    
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewControllerDisplayMode) {
        switch displayMode {
        case .primaryHidden:
            let barButtonItem = svc.displayModeButtonItem
            barButtonItem.title = NSLocalizedString("Personal", comment: "Personal")
            navigationItem.setLeftBarButton(barButtonItem, animated: true)
        case.allVisible:
            navigationItem.setLeftBarButton(nil, animated: true)
        default:
            break
        }
    }
    
    func splitViewController(_ splitController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        // Return true to indicate that the collapse has been handled by doing nothing.  The secondary controller will be discarded.
        return true
    }
}

// MARK: - UINavigationControllerDelegate
extension ItemListViewController: UINavigationControllerDelegate {
}
