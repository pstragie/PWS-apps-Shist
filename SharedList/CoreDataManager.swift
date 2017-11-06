//
//  CoreDataManager.swift
//  SharedList
//
//  Created by Pieter Stragier on 04/11/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import CoreData
import UIKit
import Foundation

final class CoreDataManager {
    weak var delegate: CoreDataManager?
    
    // MARK: - Properties
    private let modelName: String
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    // MARK: - Initialization
    init(modelName: String) {
        self.modelName = modelName
    }
    
    // MARK: - Core Data Stack
    
    
    // MARK: - fetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController<Personal> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Personal> = Personal.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "header", ascending: true)]
        // Create Fetched Results Controller
        let context = self.appDelegate.persistentContainer.viewContext
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: #keyPath(Personal.header), cacheName: nil)
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self as? NSFetchedResultsControllerDelegate
        return fetchedResultsController
    }()

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
    
    // MARK: - save Attributes
    func saveNewItem(entitynaam: String, header: String, item: String, planned: Bool, done: Bool) {
        let moc = self.appDelegate.persistentContainer.viewContext
        print("saving new item...")
        
        if let newItem = createRecordForEntity(entitynaam, inManagedObjectContext: moc) {
            newItem.setValue(header, forKey: "header")
            newItem.setValue(item, forKey: "item")
            newItem.setValue(planned, forKey: "planned")
            newItem.setValue(done, forKey: "done")
            newItem.setValue(Date(), forKey: "datum")
        }
        do {
            try moc.save()
            print("context saved")
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    func saveNewHeader(entitynaam: String, header: String) {
        let moc = self.appDelegate.persistentContainer.viewContext
        print("saving new header")
        
        if let newHeader = createRecordForEntity(entitynaam, inManagedObjectContext: moc) {
            newHeader.setValue(header, forKey: "header")
            newHeader.setValue(Date(), forKey: "datum")
        }
        do {
            try moc.save()
            print("context saved")
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    func addItemToHeader(entitynaam: String, header: String, item: String, planned: Bool, done: Bool) {
        let moc = self.appDelegate.persistentContainer.viewContext
        print("adding item to existing header")
        
        let eH = fetchRecordsForEntity(entitynaam, key: "header", arg: header, inManagedObjectContext: moc)
        
        for existingHeader in eH {
            existingHeader.setValue(Date(), forKey: "datum")
            existingHeader.setValue(item, forKey: "item")
            existingHeader.setValue(planned, forKey: "planned")
            existingHeader.setValue(done, forKey: "done")
        }
        do {
            try moc.save()
            print("context saved")
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
        
    }
    
    func removeItem(entitynaam: String, header: String, item: String, planned: Bool, done: Bool) {
        let moc = self.appDelegate.persistentContainer.viewContext
        print("removing item")
        let eI = fetchRecordsForEntity("Personal", key: "item", arg: item, inManagedObjectContext: moc)
        for existingItem in eI {
            if (existingItem.value(forKey: "header") as! String) == header {
                moc.delete(existingItem)
            }
        }
        do {
            try moc.save()
            print("context saved")
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    func removeHeader(entitynaam: String, header: String) {
        let moc = self.appDelegate.persistentContainer.viewContext
        print("removing section")
        let eH = fetchRecordsForEntity("Personal", key: "header", arg: header, inManagedObjectContext: moc)
        for object in eH {
            moc.delete(object)
        }
        do {
            try moc.save()
            print("context saved")
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - fetchRecordsForEntity
    func fetchRecordsForEntity(_ entity: String, key: String, arg: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [NSManagedObject] {
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
    
    func getHeaderArray(_ entitynaam: String) -> Array<String> {
        let moc = self.appDelegate.persistentContainer.viewContext
        var headerArray: Array<String> = []
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entitynaam)
        request.resultType = .dictionaryResultType
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
            return ["header 1"]
        }

        return headerArray
    }
    
    func getItemsArray(_ entitynaam: String, header: String) -> Array<String> {
        let moc = self.appDelegate.persistentContainer.viewContext
        var itemArray: Array<String> = []
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entitynaam)
        request.resultType = .dictionaryResultType
        request.predicate = NSPredicate(format: "header == %@", header)
        
        do {
            let result = try moc.fetch(request)
            let resultsDict = result as! [[String: Any]]
            for r in resultsDict {
                if r["item"] != nil {
                    itemArray.append(r["item"]! as! String)
                } else {
                    itemArray = []
                }
            }
        } catch {
            return []
        }
        return itemArray
    }
    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = self.appDelegate.persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    func printCoreData() {
        let headers = getHeaderArray("Personal")
        for header in headers {
            let items = getItemsArray("Personal", header: header)
            print(header)
            print(items)
        }
    }
}

