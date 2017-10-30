//
//  SharedListsViewController.swift
//  SharedList
//
//  Created by Pieter Stragier on 30/10/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit
import CoreData

class SharedListsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var listop: String = "List"
    var segAttr = NSDictionary(object: UIFont(name: "Helvetica", size: 20.0)!, forKey: NSFontAttributeName as NSCopying)
    @IBOutlet weak var subview: UIView!
    @IBOutlet var tableView: UITableView!
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
    
    // MARK: - Load Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupLayout()
        self.tableView.isEditing = true
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
        tableView.layer.borderColor = UIColor.yellow.cgColor
        tableView.layer.borderWidth = 3
    }

    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListsCell")
        return cell!
    }
}

