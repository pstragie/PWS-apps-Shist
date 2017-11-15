//
//  Lijst.swift
//  SharedList
//
//  Created by Pieter Stragier on 15/11/2017.
//  Copyright © 2017 PWS. All rights reserved.
//

import Foundation
import CloudKit
import MapKit

class Lijst: NSObject, MKAnnotation {
    
    // MARK: - Properties
    var record: CKRecord!
    var name: String!
    var location: CLLocation!
    weak var database: CKDatabase!
    var assetCount = 0
    
    var privateList: Bool {
        guard let isPrivate = record["Private"] as? NSNumber else { return false }
        return isPrivate.boolValue
    }
    
    var sharedList: Bool {
        guard let isShared = record["Shared"] as? NSNumber else { return false }
        return isShared.boolValue
    }
    
    // MARK: - Map Annotation Properties
    var coordinate: CLLocationCoordinate2D {
        return location.coordinate
    }
    
    var title: String? {
        return name
    }
    
    // MARK: - Initializers
    init(record: CKRecord, database: CKDatabase) {
        self.record = record
        self.database = database
        
        self.name = record["Name"] as? String
    }
    
    func fetchRating(_ completion: @escaping (_ rating: Double, _ isUser: Bool) -> ()) {
        Model.sharedInstance.userInfo.userID() { [weak self] userRecord, error in
            self?.fetchRating(userRecord, completion: completion)
        }
    }
    
    func fetchRating(_ userRecord: CKRecordID!, completion: (_ rating: Double, _ isUser: Bool) -> ()) {
        // Capability not yet implemented.
        completion(0, false)
    }
    
    func fetchNote(_ completion: @escaping (_ note: String?) -> ()) {
        Model.sharedInstance.fetchNote(self) { note, error in
            completion(note)
        }
    }
    
    /*
    func fetchPhotos(_ completion: @escaping (_ assets: [CKRecord]?) -> ()) {
        let predicate = NSPredicate(format: "Lijst == %@", record)
        let query = CKQuery(recordType: "LijstPhoto", predicate: predicate)
        
        // Intermediate Extension Point - with cursors
        database.perform(query, inZoneWith: nil) { [weak self] results, error in
            defer {
                completion(results)
            }
            
            guard error == nil,
                let results = results else {
                    return
            }
            
            self?.assetCount = results.count
        }
    }
    
    func loadCoverPhoto(completion:@escaping (_ photo: UIImage?) -> ()) {
        // Replace this stub.
        completion(nil)
    }
    */
}
