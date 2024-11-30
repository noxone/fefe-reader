//
//  PersistenseController.swift
//  FefeReader
//
//  Created by Olaf Neumann on 26.11.24.
//

import Foundation
import CoreData

private let gCloudKitContainerIdentifier = "iCloud.org.olafneumann.FefeBlogReader"

class PersistenceController: NSObject, ObservableObject {
    static let shared = PersistenceController()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FefeReader")
        container.loadPersistentStores(completionHandler: { storeDescription, error in
            if let error = error as NSError? {
                RaiseError.raise()
            }
        })
        return container
    }()
    
    private var _privatePersistentStore: NSPersistentStore?
    var privatePersistentStore: NSPersistentStore {
        return _privatePersistentStore!
    }
    
    private var _sharedPersistentStore: NSPersistentStore?
    var sharedPersistentStore: NSPersistentStore {
        return _sharedPersistentStore!
    }
    
    /*lazy var cloudKitContainer: CKContainer = {
        return CKContainer(identifier: gCloudKitContainerIdentifier)
    }()*/
    
}
