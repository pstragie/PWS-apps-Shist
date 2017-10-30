//
//  PersonalListsViewController.swift
//  SharedList
//
//  Created by Pieter Stragier on 30/10/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit
import CoreData

class PersonalListsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var listop: String = "List"
    var segAttr = NSDictionary(object: UIFont(name: "Helvetica", size: 20.0)!, forKey: NSFontAttributeName as NSCopying)
    var indxpth: IndexPath = []
    
    @IBOutlet weak var messageButton: UIButton!
    let localdata = UserDefaults.standard
    
    var dataDict: Dictionary<String, Array<String>> = [:]
    @IBOutlet weak var subview: UIView!
    @IBOutlet weak var tableView: UITableView!

    @IBAction func messageButton(_ sender: UIButton) {
        tableView.isHidden = false
    }
    @IBOutlet weak var segButtonTop: UISegmentedControl!
    @IBAction func segButtonChanged(_ sender: UISegmentedControl) {
        switch segButtonTop.selectedSegmentIndex {
        case 0:
            listop = "List"
        case 1:
            listop = "Daily"
        case 2:
            listop = "Monthly"
        case 3:
            listop = "Yearly"
        default:
            listop = "List"
            break
        }
    }
    
    // MARK: - Load cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupLayout()
        self.tableView.isEditing = true
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        self.updateView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - Layout
    func setupLayout() {
        segButtonTop.setTitle("List", forSegmentAt: 0)
        segButtonTop.setTitle("Daily", forSegmentAt: 1)
        segButtonTop.setTitle("Monthly", forSegmentAt: 2)
        segButtonTop.setTitle("Yearly", forSegmentAt: 3)
        
        self.segButtonTop.setTitleTextAttributes(segAttr as? [AnyHashable : Any], for: .normal)
        subview.layer.cornerRadius = 25
        tableView.layer.cornerRadius = 25
        tableView.layer.borderColor = UIColor.blue.cgColor
        tableView.layer.borderWidth = 3
    }

    // MARK: - fetchedResultsController
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Personal> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Personal> = Personal.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "item", ascending: true)]
        var format: String = "list BEGINSWITH[c] %@"
        let predicate = NSPredicate(format: format, "list")
        fetchRequest.predicate = predicate
        // Create Fetched Results Controller
        
        let context = self.appDelegate.persistentContainer.viewContext
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self as? NSFetchedResultsControllerDelegate
        return fetchedResultsController
    }()
   
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableCell(withIdentifier: "header")
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let header1: String? = "Header 1"
        return header1
    }
    func addHeader() {
        // Do something
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Fetch Items
        let item = [Personal]()
        if item.count > 0 {
            return item.count
        } else {
            return 1
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let items = [Personal]().count
        if items > 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CellModel.reuseIdentifier, for: indexPath) as? CellModel else {
                fatalError("Unexpected Index Path")
            }
            
            // Fetch Items
            let item = fetchedResultsController.object(at: indexPath)
            
            // Configure Cell
            cell.layer.cornerRadius = 3
            cell.layer.masksToBounds = true
            cell.layer.borderWidth = 1
    /*
            if item.planned == true {
                cell.planned = UIImage // image of checked box
            } else {
                cell.planned = UIImage // image of unchecked box
            }
            if item.done == true {
                cell.done = UIImage // image of checked box
            } else {
                cell.done = UIImage // image of unchecked box
            }
    */
            cell.listitem.text = item.item
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ListsCell")
            return cell!
        }
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.indxpth = indexPath
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        let currentlist = listop
        let sectionHeaderView = tableView.headerView(forSection: indxpth.section)
        let sectionTitle = sectionHeaderView?.textLabel?.text
        let cell = tableView.cellForRow(at: indexPath)
        let item = cell?.inputAssistantItem
        self.saveAttributes(entitynaam: "Personal", dict: ["list": currentlist, "header": sectionTitle!, "item": item!])
        
        return indexPath
    }
    
    // MARK: - saveAttributes
    func saveAttributes(entitynaam: String, dict: [String:Any]) {
        let managedObjectContext = appDelegate.persistentContainer.viewContext
        print("saving attributes...")
        
        if entitynaam == "Personal" {
            if let newItem = createRecordForEntity("Personal", inManagedObjectContext: managedObjectContext) {
                for (key, value) in dict {
                    newItem.setValue(value, forKey: key)
                }
                newItem.setValue(Date(), forKey: "datum")
            }
        }
        do {
            try managedObjectContext.save()
            print("context saved")
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }

    }
    // MARK: - createRecordForEntity
    private func createRecordForEntity(_ entity: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> NSManagedObject? {
        // Helpers
        var result: NSManagedObject?
        // Create Entity Description
        let entityDescription = NSEntityDescription.entity(forEntityName: entity, in: managedObjectContext)
        if let entityDescription = entityDescription {
            // Create Managed Object
            result = NSManagedObject(entity: entityDescription, insertInto: managedObjectContext)
        }
        return result
    }
    
    // MARK: - fetchRecordsForEntity
    private func fetchRecordsForEntity(_ entity: String, key: String, arg: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [NSManagedObject] {
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let predicate = NSPredicate(format: "%K == %@", key, arg)
        fetchRequest.predicate = predicate
        // Helpers
        var result = [NSManagedObject]()
        
        do {
            // Execute Fetch Request
            let records = try managedObjectContext.fetch(fetchRequest)
            if let records = records as? [NSManagedObject] {
                result = records
            }
        } catch {
            print("Unable to fetch managed objects for entity \(entity).")
        }
        return result
    }
    
    private func updateView() {
        let items = [Personal]()
        let hasItems = items.count > 0
        tableView.isHidden = !hasItems
        messageButton.isHidden = hasItems
    }
}

