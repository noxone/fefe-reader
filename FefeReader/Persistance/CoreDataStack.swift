//
//  CoreDataStack.swift
//  FefeReader
//
//  Created by Olaf Neumann on 10.06.22.
//

import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()

    private init() {}

    var managedObjectContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }

    var workingContext: NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.managedObjectContext
        return context
    }
    
    @discardableResult
    func withMainContext<T>(action: (NSManagedObjectContext) -> T) -> T {
        defer {
            saveContext()
        }
        var result: T? = nil
        self.managedObjectContext.performAndWait {
            result = action(managedObjectContext)
        }
        return result!
    }
    
    @discardableResult
    func withWorkingContext<T>(action: (NSManagedObjectContext) -> T) -> T {
        let context = workingContext
        defer {
            saveWorkingContext(context: context)
        }
        return action(context)
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FefeReader")
        container.loadPersistentStores(completionHandler: { storeDescription, error in
            if let error = error as NSError? {
                RaiseError.raise()
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext() {
        self.managedObjectContext.performAndWait {
            if self.managedObjectContext.hasChanges {
                do {
                    try self.managedObjectContext.save()
                    appPrint("Main context saved")
                } catch {
                    appPrint("Unable to save main context.", error)
                    RaiseError.raise()
                }
            }
        }
    }

    func saveWorkingContext(context: NSManagedObjectContext) {
        do {
            try context.save()
            appPrint("Working context saved")
            saveContext()
        } catch (let error) {
            context.rollback()
            appPrint("Unable to save working context.", error)
            RaiseError.raise()
        }
    }
}
