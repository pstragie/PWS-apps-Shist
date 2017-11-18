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
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newListTextField: UITextField!
    @IBOutlet weak var addNewListButton: UIButton!
    
    // MARK: - IBActions
    @IBAction func editButton(_ sender: UIButton) {
        if tableView.isEditing == true {
            tableView.isEditing = false
        } else {
            tableView.isEditing = true
        }
    }
    @IBAction func addNewList(_ sender: UIButton) {
        coreDelegate.addNewList("Lists", input: newListTextField.text!, storage: "personal")
        performFetch()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    func performFetch() {
        do {
            try coreDelegate.fetchedResultsControllerListsPersonal.performFetch()
        } catch {
            let fetchError = error as NSError
            fatalError("Could not fetch records: \(fetchError)")
        }
    }
    
    func setupLayout() {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        tableView.isEditing = false
        newListTextField.addTarget(self, action: #selector(newListTextFieldChangeDetected), for: .allEditingEvents)
        addNewListButton.isEnabled = false
    }
    
    func newListTextFieldChangeDetected(_ textField: UITextField) {
        if newListTextField.text == "" {
            addNewListButton.isEnabled = false
        } else {
            addNewListButton.isEnabled = true
        }
    }
    func insertData() {
        performFetch()
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
