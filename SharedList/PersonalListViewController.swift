//
//  PersonalListViewController.swift
//  SharedList
//
//  Created by Pieter Stragier on 07/11/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

final class PersonalListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let coreDelegate = CoreDataManager(modelName: "dataModel")
    let localdata = UserDefaults.standard
    var listItemIndexPath: IndexPath?
    var personalItemsViewController: ItemListViewController? = nil
    var locationManager: CLLocationManager!
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addNewListButton: UIButton!
    
    @IBOutlet weak var privateLabel: UILabel!
    @IBOutlet weak var sideView: UIView!
    // MARK: - IBActions
    @IBAction func editButton(_ sender: UIButton) {
        if tableView.isEditing == true {
            tableView.isEditing = false
        } else {
            tableView.isEditing = true
        }
    }
    @IBAction func addNewList(_ sender: UIButton) {
        
        performFetch()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadList), name: NSNotification.Name(rawValue: "reload"), object: nil)
        let startIndexPath:IndexPath = IndexPath(row: 0, section: 0)
        tableView.selectRow(at: startIndexPath, animated: true, scrollPosition: .none)
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.personalItemsViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? ItemListViewController
        }
        
        setupLayout()
    }
    override func viewWillAppear(_ animated: Bool) {
        performFetch()
        if self.splitViewController!.isCollapsed {
            self.tableView.deselectRow(at: tableView.indexPathForSelectedRow!, animated: true)
        }
        
        super.viewWillAppear(true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        coreDelegate.saveContext()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        tableView.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Functions
    func reloadList() {
        self.tableView.reloadData()
    }
    func performFetch() {
        do {
            try coreDelegate.fetchedResultsControllerListsPersonal.performFetch()
        } catch {
            let fetchError = error as NSError
            fatalError("Could not fetch records: \(fetchError)")
        }
    }
    

    func setupLayout() {
        self.view.layer.backgroundColor = UIColor.lightGray.cgColor
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        self.navigationController?.title = "Private lists"
        tableView.isEditing = false
        sideView.layer.backgroundColor = UIColor.Palette.blueVar5.cgColor
        privateLabel.tintColor = UIColor.white
        privateLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        privateLabel.font.withSize(30)
        privateLabel.adjustsFontSizeToFitWidth = true
        privateLabel.textAlignment = .center
        addNewListButton.isEnabled = false
        
    }
    
    func insertData() {
        performFetch()
    }
    
    func reminderPassed(listname:String, list:Lists) -> Bool {
        let moc = self.appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Personal")
        let predicate = NSPredicate(format: "lists.listname == %@", listname)
        request.predicate = predicate
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["item"]
        var resultsDict: Array<Dictionary<String,Any>> = [[:]]
        do {
            let result = try moc.fetch(request)
            resultsDict = result as! [[String:Any]]
        } catch {
            print("error fetching: \(error.localizedDescription)")
        }
        
        for r in resultsDict {
            let item = r["item"] as! String
            // fetch duedate & duedateSet from Personal
            let newRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Personal")
            let sortDescriptor = [NSSortDescriptor(key: "item", ascending: true)]
            newRequest.sortDescriptors = sortDescriptor
            let subpred1 = NSPredicate(format: "lists.listname == %@", listname)
            let subpred2 = NSPredicate(format: "item == %@", item)
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [subpred1, subpred2])
            newRequest.predicate = predicate
            //let aFetchedItemController = NSFetchedResultsController(fetchRequest: newRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
            var set: Bool = false
            var date: NSDate?
            var interval: Double = 0.0
            var result = [Personal]()
            do {
                let records = try moc.fetch(newRequest)
                if let records = records as? [Personal] {
                    result = records
                }
                if let itemRecord = result.first {
                    set = itemRecord.duedateSet
                    if set == true {
                        date = itemRecord.duedate
                        interval = (date?.timeIntervalSinceNow)!
                    }
                }
                
                
            } catch {
                print("Could not fetch")
            }
            // if duedateSet == true and duedate interval < 0 -> return true
            if set == true && interval < 0.0 {
                return true
            }
        }
        
        return false
    }
    
    func getCount(listname:String) -> Dictionary<String,Int> {
        let moc = self.appDelegate.persistentContainer.viewContext
        var itemSum: Int = 0
        var plannedSum: Int = 0
        var doneSum: Int = 0
        var result:Dictionary<String,Int> = [:]
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Personal")
        let predicate = NSPredicate(format: "lists.listname == %@", listname)
        request.predicate = predicate
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["item", "planned", "done"]
        
        do {
            let result = try moc.fetch(request)
            let resultsDict = result as! [[String: Any]]
            for r in resultsDict {
                if r["item"] as! String != "" {
                    itemSum += 1
                }
                plannedSum += r["planned"] as! Int
                doneSum += r["done"] as! Int
            }
        } catch {
            print("error fetching: \(error.localizedDescription)")
        }
        result["items"] = itemSum
        result["planned"] = plannedSum
        result["done"] = doneSum
        return result
    }
    func countItems(lijstnaam:String) -> Int {
        // fetch items in each list
        let result = getCount(listname: lijstnaam)
        return result["items"]!
    }
    func countPlanned(lijstnaam:String) -> Int {
        let planned = getCount(listname: lijstnaam)["planned"]
        return planned!
    }
    
    func countDone(lijstnaam:String) -> Int {
        let done = getCount(listname: lijstnaam)["done"]
        return done!
    }
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let lists = coreDelegate.fetchedResultsControllerListsPersonal.fetchedObjects else { return 0 }
        return lists.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            let itemListViewController = controllers[controllers.count-1] as? ItemListViewController
            itemListViewController?.input.becomeFirstResponder()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ListCellModel.reuseIdentifier, for: indexPath) as? ListCellModel else {
            fatalError("Unexpected Index Path")
        }
        let list = coreDelegate.fetchedResultsControllerListsPersonal.object(at: indexPath)
        // Configure the cell...
        cell.delegatePersonalCell = self
        
        cell.listName.text = list.listname
        let itemtotal:Int = countItems(lijstnaam: list.listname!)
        let plannedtotal:Int = countPlanned(lijstnaam: list.listname!)
        let donetotal:Int = countDone(lijstnaam: list.listname!)
        if donetotal == itemtotal && donetotal != 0 {
            cell.cellView.layer.shadowColor = UIColor.green.cgColor
            cell.cellView.layer.shadowRadius = 6
            cell.cellView.layer.shadowOffset = CGSize.zero
            cell.cellView.layer.shadowOpacity = 1.0
        } else if reminderPassed(listname: list.listname!, list: list) == true {
            cell.cellView.layer.shadowColor = UIColor.red.cgColor
            cell.cellView.layer.shadowRadius = 6
            cell.cellView.layer.shadowOffset = CGSize.zero
            cell.cellView.layer.shadowOpacity = 1.0
        } else if plannedtotal == itemtotal && plannedtotal != 0 {
            cell.cellView.layer.shadowColor = UIColor.yellow.cgColor
            cell.cellView.layer.shadowRadius = 6
            cell.cellView.layer.shadowOffset = CGSize.zero
            cell.cellView.layer.shadowOpacity = 1.0
        } else {
            cell.cellView.layer.shadowOpacity = 0.0
        }
        cell.numberOfItems.text = "\(itemtotal) items, \(plannedtotal) planned, \(donetotal) done"
        return cell
     }
    
    
     // Override to support conditional editing of the table view.
     func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
     }
    
    
     // Override to support editing the table view.
     func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ListCellModel
        let listname = cell.listName.text
        if editingStyle == .delete {
            // Delete the list from the core data
            coreDelegate.removeList(entitynaam: "Lists", listname: listname!,  fromList: "plist")
            // Delete the row from the tableView
            performFetch()
            tableView.reloadData()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
     }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
     // Override to support rearranging the table view.
     func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        var lists = coreDelegate.fetchedResultsControllerListsPersonal.fetchedObjects
        
        let rowToMove = lists?[fromIndexPath.row]
        lists!.remove(at: fromIndexPath.row)
        lists!.insert(rowToMove!, at: to.row)
     }
    
    
    
     // Override to support conditional rearranging of the table view.
     func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
     }
    
    
     // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        switch segue.identifier! {
        case "seguePersonalToItems":
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = coreDelegate.fetchedResultsControllerListsPersonal.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! ItemListViewController
                controller.items = object
                controller.listName = object.listname
                controller.entity = "personal"
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
            
        default:
            break
        }
        
    }
    @IBAction func backUnwindAction(unwindSegue: UIStoryboardSegue) {
        dismiss(animated: true, completion: nil)
    }
}
