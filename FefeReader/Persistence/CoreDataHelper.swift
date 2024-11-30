//
//  ContextualInfoForSaving.swift
//  FefeReader
//
//  Created by Olaf Neumann on 26.11.24.
//

import CoreData
// TODO: import CloudKit

extension NSPersistentStore {
    func contains(manageObject: NSManagedObject) -> Bool {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: manageObject.entity.name!)
        fetchRequest.predicate = NSPredicate(format: "self == %@", manageObject)
        fetchRequest.affectedStores = [self]
        
        if let context = manageObject.managedObjectContext,
           let result = try? context.count(for: fetchRequest), result > 0 {
            return true
        }
        return false
    }
}

extension NSManagedObject {
    /*var persistentStore: NSPersistentStore? {
        let persistenceController = PersistenceController.shared
        
        if persistenceController.store
        
        if persistenceController.sharedPersistentStore.contains(manageObject: self) {
            return persistenceController.sharedPersistentStore
        } else if persistenceController.privatePersistentStore.contains(manageObject: self) {
            return persistenceController.privatePersistentStore
        }
        return nil
    }*/
}

extension NSManagedObjectContext {
    /**
     Contextual information for handling error that happens when saving a managed object context.
     */
    enum ContextualInfoForSaving: String {
        case addBlogEntry, updateBlogEntry, deleteBlogEntry
        case sheetOnDismiss
        case deduplicateAndWait
    }
    /**
     Save a context and handle the save error. This sample simply prints the error message. Real apps should
     consider comprehensive error handling based on the contextual information.
     */
    func save(with contextualInfo: ContextualInfoForSaving) {
        if hasChanges {
            do {
                try save()
                appPrint("Saved for: \(contextualInfo.rawValue)")
            } catch {
                print("\(#function): Failed to save Core Data context for \(contextualInfo.rawValue): \(error)")
            }
        }
    }
}

/**
 A convenience method for creating background contexts that specify the app as their transaction author.
 */
extension NSPersistentContainer {
    func newTaskContext() -> NSManagedObjectContext {
        let context = newBackgroundContext()
        // context.transactionAuthor = TransactionAuthor.app
        return context
    }
    
    /**
     Fetch and return shares in the persistent stores.
     */
    /*func fetchShares(in persistentStores: [NSPersistentStore]) throws -> [CKShare] {
        var results = [CKShare]()
        for persistentStore in persistentStores {
            do {
                let shares = try fetchShares(in: persistentStore)
                results += shares
            } catch let error {
                print("Failed to fetch shares in \(persistentStore).")
                throw error
            }
        }
        return results
    }*/
}

