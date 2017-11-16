//
//  SharedListViewController.swift
//  SharedList
//
//  Created by Pieter Stragier on 30/10/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class SharedListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let coreDelegate = CoreDataManager(modelName: "dataModel")
    let localdata = UserDefaults.standard
    var listItemIndexPath: IndexPath?
    var sharedItemsViewController: ItemListViewController?
    var locationManager: CLLocationManager!
    var clearsSelectionOnViewWillAppear: Bool = true
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBAction func editButton(_ sender: UIButton) {
        if tableView.isEditing == true {
            tableView.isEditing = false
        } else {
            tableView.isEditing = true
        }
    }
    @IBAction func addNewList(_ sender: UIButton) {
        coreDelegate.addNewList("Lists", input: newListTextField.text!, storage: "shared")
        performFetch()
        tableView.reloadData()
    }
    @IBOutlet weak var newListTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let startIndexPath:IndexPath = IndexPath(row: 0, section: 0)
        tableView.selectRow(at: startIndexPath, animated: true, scrollPosition: .none)
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.sharedItemsViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? ItemListViewController
        }
        
        setupLayout()
    }
    override func viewWillAppear(_ animated: Bool) {
        if self.splitViewController!.isCollapsed {
            self.tableView.deselectRow(at: tableView.indexPathForSelectedRow!, animated: true)
        }
        performFetch()
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
    func performFetch() {
        do {
            try coreDelegate.fetchedResultsControllerLists.performFetch()
        } catch {
            let fetchError = error as NSError
            fatalError("Could not fetch records: \(fetchError)")
        }
    }
    
    func setupLayout() {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView.isEditing = false
    }
    
    func insertData() {
        performFetch()
    }
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let lists = coreDelegate.fetchedResultsControllerLists.fetchedObjects else { return 0 }
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
        let list = coreDelegate.fetchedResultsControllerLists.object(at: indexPath)
        // Configure the cell...
        cell.listName.text = list.listname
        cell.listContentView.layer.borderWidth = 1
        cell.listContentView.layer.cornerRadius = 10
        cell.listContentView.layer.backgroundColor = UIColor.Palette.blueVar1.cgColor
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
        print("listname: \(listname!)")
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
        var lists = coreDelegate.fetchedResultsControllerLists.fetchedObjects
        
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
        case "segueSharedToItems":
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = coreDelegate.fetchedResultsControllerLists.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! ItemListViewController
                controller.items = object
                controller.listName = object.listname

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
