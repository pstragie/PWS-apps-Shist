//
//  AppDelegate.swift
//  SharedList
//
//  Created by Pieter Stragier on 30/10/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import UIKit
import CoreData
import Foundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    //let coreDelegate = CoreDataManager(modelName: "dataModel")

    var errorHandler: (Error) -> Void = {_ in }
    var appVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!
    var appBuild: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String)!
    var listArray: Array<String> = ["shopping", "to do", "phone calls to make"]
    var itemArray: Array<Dictionary<String,Any>> = [["listname": "shopping", "header": "shop A", "item": "milk"], ["listname": "shopping", "header": "Urgent", "item": "chocolate"], ["listname": "shopping", "header": "shop A", "item": "eggs"], ["listname": "shopping", "header": "shopA", "item": "water", "planned": 0, "done": 1], ["listname": "shopping", "header": "pet shop", "item": "dog food", "planned": 0, "done": 0], ["listname": "to do", "header": "dad", "item": "dishes", "planned": 0, "done": 1], ["listname": "to do", "header": "dad", "item": "pick up kids from school", "planned": 0, "done": 0], ["listname": "phone calls to make", "header": "Before 5 pm", "item": "call the bank", "iteminfo": "555-thebank-321", "planned": 0, "done": 0], ["listname": "phone calls to make", "header": "Before 5 pm", "item": "order food", "iteminfo": "555-pizza-001"]]
    // MARK: - persistentContainer
    lazy var persistentContainer: NSPersistentContainer = {
        //        print("Loading persistentContainer")
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "dataModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("CoreData error \(error), \(String(describing: error._userInfo))")
                self.errorHandler(error)
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved CoreData error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let moc = persistentContainer.viewContext
        
        if firstLaunch() == true {
            let list = Lists(context: moc)
            let pers = Personal(context: moc)
            list.listname = "Winkellijst"
            list.plist = true
            pers.header = "Aldi"
            pers.item = "Water"
            
            list.addToPersonal(pers)
            do {
                try moc.save()
            } catch {
                fatalError("Could not save")
            }
            
            /*
            // Delete the core data
            let Entities = ["Lists", "Personal", "Shared", "Contacts"]
            for E in Entities {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: E)
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                do {
                    try moc.execute(batchDeleteRequest)
                    print("all data deleted from \(E)")
                } catch {
                    print("Batch delete did not work: \(E)")
                }
            }
 */
            // seedPersistentStore
            //seedPersistentStoreOnFirstLaunch(moc)
    /*
            // Option 1
                // Create new item
            let items = NSEntityDescription.entity(forEntityName: "Personal", in: moc)
            let newItem = NSManagedObject(entity: items!, insertInto: moc)
            
            newItem.setValue("Aldi", forKey: "header")
            newItem.setValue("Koekjes", forKey: "item")
            newItem.setValue("Winkelen", forKey: "listname")
                // Create new list
            let lists = NSEntityDescription.entity(forEntityName: "Lists", in: moc)
            let newList = NSManagedObject(entity: lists!, insertInto: moc)
            newList.setValue("Winkelen", forKey: "listname")
            newList.setValue(true, forKey: "plist")
            
            newItem.setValue(NSSet(object: newList), forKey: "lists")
            
            do {
                try newItem.managedObjectContext?.save()
            } catch {
                fatalError("Could not save")
            }

            // Option 2 werkt!
            let list = Lists(context: moc)
            let item = Personal(context: moc)
            item.header = "Match"
            item.item = "Suiker"
            list.listname = "Winkellijst"
            list.plist = true
            item.lists = list
            do {
                try moc.save()
            } catch {
                fatalError("Could not save")
            }
 */
        }
        
        
        //preloadDBData()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Check for first launch
    func firstLaunch() -> Bool {
        let previouslyLaunched = UserDefaults.standard.bool(forKey: "previouslyLaunched")
        if !previouslyLaunched {
            UserDefaults.standard.set(true, forKey: "previouslyLaunched")
            return true
        } else {
            return false
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
    // MARK: - preloadDBData Core Data stack
    func preloadDBData() {
        print("Preloading DB...")
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: NSPersistentContainer.defaultDirectoryURL().relativePath + "/dataModel.sqlite") {
            print("Files do not exist!")
            let sourceSqliteURLs = [URL(fileURLWithPath: Bundle.main.path(forResource: "dataModel", ofType: "sqlite")!), URL(fileURLWithPath: Bundle.main.path(forResource: "dataModel", ofType: "sqlite-wal")!), URL(fileURLWithPath: Bundle.main.path(forResource: "dataModel", ofType: "sqlite-shm")!)]
            let destSqliteURLs = [URL(fileURLWithPath: NSPersistentContainer.defaultDirectoryURL().relativePath + "/dataMoel.sqlite"), URL(fileURLWithPath: NSPersistentContainer.defaultDirectoryURL().relativePath + "/dataModel.sqlite-wal"), URL(fileURLWithPath: NSPersistentContainer.defaultDirectoryURL().relativePath + "/dataModel.sqlite-shm")]
            print("destination: \(destSqliteURLs)")
            for index in 0 ..< sourceSqliteURLs.count {
                do {
                    try fileManager.copyItem(at: sourceSqliteURLs[index], to: destSqliteURLs[index])
                    //                    print("Files Copied!")
                } catch {
                    fatalError("Could not copy sqlite to destination.")
                }
            }
            // MARK: Print UserDefaults
            /*print("localdata: ", localdata)
             for (key, value) in localdata.dictionaryRepresentation() {
             print("\(key) = \(value) \n")
             }*/
        } else {
            //            print("Files Exist!")
            
            let sourceSqliteURLs = [URL(fileURLWithPath: Bundle.main.path(forResource: "dataModel", ofType: "sqlite")!), URL(fileURLWithPath: Bundle.main.path(forResource: "dataModel", ofType: "sqlite-wal")!), URL(fileURLWithPath: Bundle.main.path(forResource: "dataModel", ofType: "sqlite-shm")!)]
            let destSqliteURLs = [URL(fileURLWithPath: NSPersistentContainer.defaultDirectoryURL().relativePath + "/dataModel.sqlite"), URL(fileURLWithPath: NSPersistentContainer.defaultDirectoryURL().relativePath + "/dataModel.sqlite-wal"), URL(fileURLWithPath: NSPersistentContainer.defaultDirectoryURL().relativePath + "/dataModel.sqlite-shm")]
            //                print("destination: \(destSqliteURLs)")
            // Delete old db files
            //                print("...deleting old sqlite files")
            for index in 0 ..< sourceSqliteURLs.count {
                do {
                    try fileManager.removeItem(at: destSqliteURLs[index])
                } catch {
                    fatalError("Could not delete old sqlite files at destination")
                }
            }
            // Copy new db files to destination
            for index in 0 ..< sourceSqliteURLs.count {
                do {
                    try fileManager.copyItem(at: sourceSqliteURLs[index], to: destSqliteURLs[index])
                } catch {
                    fatalError("Could not copy sqlite to destination.")
                }
            }
            //                print("Files Copied!")
            //.copyUserDefaultsToUserData(managedObjectContext: persistentContainer.viewContext)
            
        }
    }

}


