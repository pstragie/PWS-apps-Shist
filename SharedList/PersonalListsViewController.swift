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

    var moc: NSManagedObjectContext!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let coreDelegate = CoreDataManager(modelName: "dataModel")
    var listop: String = "List"
    var detailIndexPath: IndexPath?
    var previouslySelected: UserHeaderTableViewCell?
    var headerSelected:Bool = false
    var selectedHeader:String?
    var textFieldIsEmpty:Bool = true
    @IBOutlet weak var topLabel: UILabel!
    
    
    @IBOutlet weak var spokenTextView: UITextView!
    var segAttr = NSDictionary(object: UIFont(name: "Helvetica", size: 20.0)!, forKey: NSFontAttributeName as NSCopying)
    
    var latestaddedHeader: String = ""
    let localdata = UserDefaults.standard
    
    @IBOutlet weak var subview: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputview: UIView!
    @IBOutlet weak var input: UITextField!
    
    // MARK: - Add new header
    @IBOutlet weak var addHeader: UIButton!
    @IBAction func addHeader(_ sender: UIButton) {
        // Input
        let item = Personal(context: moc)
        if (input.text != "") {
            item.header = input.text!
            item.item = ""
            
            headerSelected = false
            latestaddedHeader = input.text!
            coreDelegate.saveContext()
            performFetch()
            input.text = ""
            tableView.reloadData()
        } else {
            // Nothing
        }
    }
    
    // MARK: Add new item
    @IBOutlet weak var addItem: UIButton!
    @IBAction func addItem(_ sender: UIButton) {
        // Input
        let item = Personal(context: moc)
        var header: String = ""
        if (input.text != "") { // Nothing happens when field is empty
            item.item = input.text!
            item.datum = Date() as NSDate
            item.planned = false
            item.done = false
            if headerSelected == false {
                print("header not selected")
                if latestaddedHeader != "" { // Add item to last added header
                    header = latestaddedHeader
                } else { // No header added
                    header = "Shop 1"
                }
            } else { // headerSelected == true
                header = selectedHeader!
            }
            item.header = header
            // Check if the section was empty (item == nil) e.g. when a new section is added
            var itemIsEmpty: Bool = false
            var result: Array<Any> = []
            var object: [NSManagedObject]
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
            if itemIsEmpty == true {
                // Remove the empty item
                object = coreDelegate.fetchRecordsForEntity("Personal", key: "item", arg: "", inManagedObjectContext: moc)
                for o in object {
                    moc.delete(o)
                }
            }
            input.text = ""
            coreDelegate.saveContext()
            coreDelegate.printCoreData()
            performFetch()
            tableView.reloadData()
        } else {
            // Nothing
        }
        
    }
    
    func plannedChanged(index: IndexPath, bool: Bool) {
        let item = coreDelegate.fetchedResultsController.object(at: index)
        item.planned = bool
        coreDelegate.saveContext()
    }
    
    func doneChanged(index: IndexPath, bool: Bool) {
        let item = coreDelegate.fetchedResultsController.object(at: index)
        item.done = bool
        coreDelegate.saveContext()
    }
    
    // MARK: - Delete functions
    func didTapBinItem(index: IndexPath) {
        print("Bin tapped at: \(index)")
        // Delete selected item
        
        let items = coreDelegate.fetchedResultsController.object(at: index as IndexPath)

        let header = items.header
        let item = items.item
        let planned = items.planned
        let done = items.done
        coreDelegate.removeItem(entitynaam: "Personal", header: header!, item: item!, planned: planned, done: done)
        latestaddedHeader = header!
        performFetch()
        // If last item in section is removed, add empty section
        var result: Array<Any> = []
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Personal")
        let predicate = NSPredicate(format: "header == %@", header!)
        fetchRequest.predicate = predicate
        do {
            result = try moc.fetch(fetchRequest)
        } catch {
            print("Fetch did not work.")
        }
        if result.count == 0 {
            let item = Personal(context: moc)
            // Add empty section
            item.header = header!
            //item.datum = Date() as NSDate
            //item.planned = false
            //item.done = false
            item.item = ""
            
            
            headerSelected = false
            coreDelegate.saveContext()

            
        } else {
            // Do nothing
        }
        

        performFetch()
        
        tableView.reloadData()
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
    
    // MARK: - Load cycle
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
        do {
            try coreDelegate.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            fatalError("Could not fetch records: \(fetchError)")
            //            print("Unable to Perform Fetch Request")
            //            print("\(fetchError), \(fetchError.localizedDescription)")
        }
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
    
    // MARK: - Perform fetch
    func performFetch() {
        do {
            try coreDelegate.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            fatalError("Could not fetch records: \(fetchError)")
        }
    }
    // MARK: - Speech Recognition
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
    // MARK: - Layout
    func setupLayout() {
        addHeader.titleLabel?.text = "+H"
        input.addTarget(self, action: #selector(textFieldidChange(_:)), for: .editingChanged)
        input.layer.borderColor = UIColor.orange.cgColor
        input.layer.borderWidth = 2
        createGradient()
        
    }
   
    // MARK: - Text field and button behaviour
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
    
    
    
    // MARK: - Create gradient
    func createGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.brown.cgColor, UIColor.white.cgColor]
        gradient.locations = [0.0, 0.8]
        self.view.layer.insertSublayer(gradient, at: 0)
        
        let gradientInputView = CAGradientLayer()
        gradientInputView.frame = inputview.bounds
        gradientInputView.colors = [UIColor.brown.cgColor, UIColor.brown.cgColor, UIColor.white.cgColor]
        gradientInputView.locations = [0.0, 0.8, 0.99]
        self.inputview.layer.insertSublayer(gradientInputView, at: 0)
    }
    
    

    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        // Fetch all data and count number of different headers
        guard let sections = coreDelegate.fetchedResultsController.sections else { return 0 }
        return sections.count
        
//        let numberOfHeaders = coreDelegate.getHeaderArray("Personal").count
//        return numberOfHeaders
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let headerCell = tableView.dequeueReusableCell(withIdentifier: "UserHeader") as? UserHeaderTableViewCell else {
            fatalError("found nil")
        }
        // Get unique headers from core data!
        guard let sectionInfo = coreDelegate.fetchedResultsController.sections?[section] else {
            fatalError("Unexpected section")
        }
        headerCell.delegate = self
        headerCell.textLabel?.text = sectionInfo.name
        headerCell.layer.backgroundColor = UIColor.lightGray.cgColor
        
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        /*
        let header = coreDelegate.getHeaderArray("Personal")
        print("header: \(header)")
        return header[section]
 */
        guard let sectionInfo = coreDelegate.fetchedResultsController.sections?[section] else {
            fatalError("Unexpected section")
        }
        return sectionInfo.name
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Get unique headers from core data
        
        guard let sectionInfo = coreDelegate.fetchedResultsController.sections?[section] else { fatalError("Unexpected section") }
        var count: Int
        var itemIsEmpty: Bool = false
        var result: Int = 0
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Personal")
        let subpredicate1 = NSPredicate(format: "item == %@", "")
        let subpredicate2 = NSPredicate(format: "header == %@", sectionInfo.name)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [subpredicate1, subpredicate2])
        fetchRequest.predicate = predicate
        do {
            result = try moc.fetch(fetchRequest).count
            
        } catch {
            print("Batch delete did not work.")
        }
        if result == 1 {
            itemIsEmpty = true
        } else {
            itemIsEmpty = false
        }
        if sectionInfo.numberOfObjects == 1 && itemIsEmpty {
            count = 0
        } else {
            count = sectionInfo.numberOfObjects
        }
        return count
            
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
        
        let item = coreDelegate.fetchedResultsController.object(at: indexPath)
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
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // TODO: - remove from core data
            let object = coreDelegate.fetchedResultsController.object(at: indexPath)
            moc.delete(object)
            do {
                try moc.save()
                tableView.reloadData()
//                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch {
                print("Could not save.")
            }
            
        }
    }
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
    
    func configure(_ cell: CellModel, at indexPath: IndexPath) {
        // Fetch item
        let item = coreDelegate.fetchedResultsController.object(at: indexPath)
        // Configure cell
        cell.listitem.text = item.item
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        updateView()
    }
    func updateView() {
        var hasItems = false
        if let items = coreDelegate.fetchedResultsController.fetchedObjects {
            hasItems = items.count > 0
        }
        tableView.isHidden = !hasItems
        
        //activityIndicatorView.stopAnimating()
    }
}

extension PersonalListsViewController: UserHeaderTableViewCellDelegate, NSFetchedResultsControllerDelegate {
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
        
        do {
            try coreDelegate.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            fatalError("Could not fetch records: \(fetchError)")
        }        
        
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "segueToDetail":
            let destination = segue.destination as! PersonalDetailViewController
            let indexPath = tableView.indexPathForSelectedRow!
            let selectedObject = coreDelegate.fetchedResultsController.object(at: indexPath)
            destination.item = selectedObject
            detailIndexPath = indexPath
        default:
            break
        }
     
    }
    @IBAction func saveUnwindAction(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func cancelUnwindAction(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteTappedUnwindAction(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true, completion: nil)
        didTapBinItem(index: detailIndexPath!)
    }
}
