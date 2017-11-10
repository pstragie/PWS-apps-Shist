//
//  PersonalListsViewController.swift
//  SharedList
//
//  Created by Pieter Stragier on 30/10/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit
import Speech
import CoreData

class PersonalListsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SFSpeechRecognizerDelegate {

    // MARK: - Variables and constants
    weak var items: Lists?
    var listName: String?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let coreDelegate = CoreDataManager(modelName: "dataModel")
    let localdata = UserDefaults.standard
    
    
    var moc: NSManagedObjectContext!
    var listop: String = "List"
    var detailIndexPath: IndexPath?
    var previouslySelected: UserHeaderTableViewCell?
    var headerSelected:Bool = false
    var selectedHeader:String?
    var textFieldIsEmpty:Bool = true
    var segAttr = NSDictionary(object: UIFont(name: "Helvetica", size: 20.0)!, forKey: NSFontAttributeName as NSCopying)
    var latestaddedHeader: String = ""
    
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
    @IBAction func addItem(_ sender: UIButton) {
        // Input
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
                header = selectedHeader!
            }
            personalItem.setValue(header, forKey: "header")
            items?.addToPersonal(personalItem)
            // Check if the section was empty (item == nil) e.g. when a new section is added
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
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        moc = appDelegate.persistentContainer.viewContext
        
        setupLayout()
        allowSpeech()
        
        self.updateView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        performTheFetch()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        tableView.reloadData()
    }
    override func viewDidLayoutSubviews() {
        updateView()
        input.becomeFirstResponder()
        if input.text == "" {
            addHeader.isEnabled = false
            addItem.isEnabled = false
        }
        tableView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Functions
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
    
    func setupLayout() {
        pageTitle.title = items?.listname
        addHeader.titleLabel?.text = "+H"
        input.addTarget(self, action: #selector(textFieldidChange(_:)), for: .editingChanged)
        input.layer.borderColor = UIColor.Palette.brownVar4.cgColor
        inputview.layer.backgroundColor = UIColor.Palette.brownVar3.cgColor
        input.layer.borderWidth = 2
        createGradient()
        
    }
    
    func configure(_ cell: CellModel, at indexPath: IndexPath) {
        // Fetch item
        let item = coreDelegate.fetchedResultsControllerPersonal.object(at: indexPath)
        // Configure cell
        cell.listitem.text = item.item
    }
    
    func textFieldidChange(_ textField: UITextField) {
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
        var hasItems = false
        if let items = items?.personal {
            print("items: \(items.count)")
            hasItems = items.count > 0
        }
        tableView.isHidden = !hasItems
        
        //activityIndicatorView.stopAnimating()
    }
    
    func filterForList() {
        let subpred1 = NSPredicate(format: "lists.listname == %@", (items?.listname)!)
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
        filterForList()
        
        guard let sections = coreDelegate.fetchedResultsControllerPersonal.sections else {
            print("no sections found")
            return 0
        }
        print("sections count: \(sections.count)")
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let headerCell = tableView.dequeueReusableCell(withIdentifier: "UserHeader") as? UserHeaderTableViewCell else {
            fatalError("found nil")
        }
        filterForList()
        // Get unique headers from core data!
        guard let sectionInfo = coreDelegate.fetchedResultsControllerPersonal.sections?[section] else {
            fatalError("Unexpected section")
        }
        
        headerCell.delegate = self
        headerCell.textLabel?.text = sectionInfo.name
        headerCell.textLabel?.textColor = UIColor.white
        headerCell.delButton.tintColor = UIColor.white
        headerCell.editButton.tintColor = UIColor.white
        
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Get unique headers from core data
        filterForList()
        
        let count = coreDelegate.fetchedResultsControllerPersonal.sections?[section].numberOfObjects
        let header = coreDelegate.getHeaderArray("Personal", listname: (items?.listname)!).sorted()[section]
        if itemIsEmpty(header: header) {
            return count! - 1
        }
        return count!
            
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellModel.reuseIdentifier, for: indexPath) as? CellModel else {
            fatalError("Unexpected Index Path")
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
        let item = coreDelegate.fetchedResultsControllerPersonal.object(at: indexPath)
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
        return cell
    }
}

extension PersonalListsViewController: UserHeaderTableViewCellDelegate, NSFetchedResultsControllerDelegate {
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
    
    // MARK: - Header behaviour
    func didSelectUserHeaderTableViewCell(sender: UserHeaderTableViewCell, Selected: Bool) {
        print("Header Cell Selected")
        headerSelected = true
        selectedHeader = sender.textLabel?.text
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

    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "segueToDetail":
            let destination = segue.destination as! PersonalDetailViewController
            let indexPath = tableView.indexPathForSelectedRow!
            let selectedObject = coreDelegate.fetchedResultsControllerPersonal.object(at: indexPath)
            destination.item = selectedObject
            filterForList()
            let headers = coreDelegate.getHeaderArray("Personal", listname: (items?.listname)!)
            destination.headerlist = headers
            detailIndexPath = indexPath
        default:
            break
        }
     
    }
    @IBAction func saveUnwindAction(unwindSegue: UIStoryboardSegue) {
        
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
