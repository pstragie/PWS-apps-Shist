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
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    //let coreDelegate = CoreDataManager(modelName: "dataModel")

    var errorHandler: (Error) -> Void = {_ in }
    var appVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)!
    var appBuild: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String)!
    
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
        print("NSHomeDir: \(NSHomeDirectory())")
        guard let tabBarController = window?.rootViewController as? UITabBarController,
            let splitViewController = tabBarController.viewControllers?.first as? UISplitViewController,
            let navigationController = splitViewController.viewControllers.last as? UINavigationController,
            let detailViewController = navigationController.topViewController as? ItemListViewController else {
                return true
        }
        
        splitViewController.delegate = detailViewController
        if firstLaunch() == true {
            loadSomeItems()
        }
        
        // iOS 10 support
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in }
            application.registerForRemoteNotifications()
        }
        
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
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewerController:UIViewController!, ontoPrimaryViewController primaryViewController:UIViewController!) -> Bool {
        if let secondaryAsNavController = secondaryViewerController as? UINavigationController {
            if let topAsDetailController = secondaryAsNavController.topViewController as? ItemListViewController {
                if topAsDetailController.items == nil {
                    return true
                }
            }
        }
        
        return false
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
    // Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        // Print it to console
        print("APNs device token: \(deviceTokenString)")
        
        // Persist it in your backend in case it's new
        UserDefaults.standard.set(deviceTokenString, forKey: "deviceTokenforPushMessages")
    }
    
    // Called when APNs failed to register the device for push notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Print the error to console (you should alert the user that the registration failed)
        print("APNs registration failed: \(error)")
    }
    
    // Push notification received
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Print notification payload data
        print("Push notification received: \(userInfo)")
    }
    
    func loadSomeItems() {
        print("preloading some data")
        let moc = self.persistentContainer.viewContext
        let list = Lists(context: moc)
        let pers = Personal(context: moc)
        let shar = Shared(context: moc)
        list.listname = "Winkellijst"
        list.plist = true
        list.slist = true
        pers.header = "Aldi"
        pers.item = "Water"
        pers.listname = "Winkellijst"
        shar.header = "Match"
        shar.item = "Wine"
        shar.listname = "Shopping List"
        list.addToPersonal(pers)
        list.addToShared(shar)
        do {
            try moc.save()
        } catch {
            fatalError("Could not save")
        }
        let list2 = Lists(context: moc)
        let pers2 = Personal(context: moc)
        list2.listname = "Bellen"
        list2.plist = true
        list2.slist = false
        pers2.header = "Vandaag"
        pers2.item = "Mama"
        pers2.listname = "Bellen"
        list2.addToPersonal(pers2)
        do {
            try moc.save()
        } catch {
            fatalError("Could not save")
        }
    }
}


