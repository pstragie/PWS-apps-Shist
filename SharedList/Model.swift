//
//  Model.swift
//  SharedList
//
//  Created by Pieter Stragier on 15/11/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import Foundation
import CloudKit
import CoreLocation

// Specify the protocol to be used by view controllers to handle notifications.
protocol ModelDelegate {
    func errorUpdating(_ error: NSError)
    func modelUpdated()
}

class Model {
    
    // MARK: - Properties
    let LijstType = "Lijst"
    let NoteType = "Note"
    static let sharedInstance = Model()
    var delegate: ModelDelegate?
    var items: [Lijst] = []
    let userInfo: UserInfo
    
    // Define databases.
    
    // Represents the default container specified in the iCloud section of the Capabilities tab for the project.
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    
    // MARK: - Initializers
    init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
        
        userInfo = UserInfo(container: container)
    }
    
    @objc func refresh() {
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Lijst", predicate: predicate)
        
        publicDB.perform(query, inZoneWith: nil) { [unowned self] results, error in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    self.delegate?.errorUpdating(error! as NSError)
                    print("Cloud Query Error - Refresh: \(String(describing: error))")
                }
                return
            }
            
            self.items.removeAll(keepingCapacity: true)
            
            for record in results! {
                let establishment = Lijst(record: record, database: self.publicDB)
                self.items.append(establishment)
            }
            
            DispatchQueue.main.async {
                self.delegate?.modelUpdated()
            }
        }
    }
    
    func establishment(_ ref: CKReference) -> Lijst! {
        let matching = items.filter { $0.record.recordID == ref.recordID }
        return matching.first
    }
    
    func fetchEstablishments(_ location:CLLocation, radiusInMeters:CLLocationDistance) {
        // Replace this stub.
        
        DispatchQueue.main.async {
            self.delegate?.modelUpdated()
            print("model updated")
        }
    }
    
    // MARK: - Notes
    func fetchNotes(_ completion: @escaping (_ notes: [CKRecord]?, _ error: NSError?) -> () ) {
        
        let query = CKQuery(recordType: NoteType, predicate: NSPredicate(value: true))
        
        privateDB.perform(query, inZoneWith: nil) { results, error in
            completion(results, error as NSError?)
        }
    }
    
    func fetchNote(_ establishment: Lijst, completion:(_ note: String?, _ error: NSError?) ->()) {
        // Capability not yet implemented.
        completion(nil, nil)
    }
    
    func addNote(_ note: String, establishment: Lijst!, completion: (_ error: NSError?)->()) {
        // Capability not yet implemented.
        completion(nil)
    }
}
