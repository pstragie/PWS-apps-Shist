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
    var itemdict: Dictionary<String, Dictionary<String,Dictionary<String, Bool>>> = ["shop 1": ["milk": ["planned": false, "done": false], "chocolate": ["planned": false, "done": false], "eggs": ["planned": false, "done": false]], "shop 2": ["dog food": ["planned": false, "done": false]]]
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
        /*
        if firstLaunch() == true {
            seedPersistentStoreOnFirstLaunch(moc)
        } else {
            print("Not the first launch!")
        }
        */
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Personal")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try moc.execute(batchDeleteRequest)
        } catch {
            print("Batch delete did not work.")
        }
        seedPersistentStoreOnFirstLaunch(moc)
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
    
    func seedPersistentStoreOnFirstLaunch(_ managedObjectContext: NSManagedObjectContext) {
            print("First Launch! Seed PersistentStore")
            let Entities = ["Personal", "Shared"]
            for entitynaam in Entities {
                loadDictIntoCoreData(entitynaam: entitynaam)
        }
    }
    
    func loadDictIntoCoreData(entitynaam: String) {
        for (header, values) in itemdict {
            for (item, bools) in values {
                let planned = bools["planned"]
                let done = bools["done"]
                CoreDataManager(modelName: "dataModel").saveNewItem(entitynaam: entitynaam, header: header, item: item, planned: planned!, done: done!)
            }
        }
    }
    
}


