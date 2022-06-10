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
    
    func readForUi<T>(action: (NSManagedObjectContext) throws -> T) rethrows -> T {
        try managedObjectContext.performAndWait {
            return try action(managedObjectContext)
        }
    }
    
    @discardableResult
    func withMainContext<T>(action: (NSManagedObjectContext) throws -> T) rethrows -> T {
        return try with(context: managedObjectContext, action: action)
    }
    
    @discardableResult
    func withWorkingContext<T>(action: (NSManagedObjectContext) throws -> T) rethrows -> T {
        return try with(context: workingContext, action: action)
    }
    
    func update<T: NSManagedObject>(_ object: T, action: (T) -> ()) {
        with(context: object.managedObjectContext) { _ in
            action(object)
        }
    }
    
    @discardableResult
    func with<T>(context optionalContext: NSManagedObjectContext?, action: (NSManagedObjectContext) throws -> T) rethrows -> T {
        let context = optionalContext ?? managedObjectContext
        let isMainContext = context == managedObjectContext
        defer {
            if isMainContext {
                saveContext()
            } else {
                saveWorkingContext(context)
            }
        }
        if isMainContext {
            var result: T? = nil
            try self.managedObjectContext.performAndWait {
                result = try action(managedObjectContext)
            }
            return result!
        } else {
            return try action(context)
        }
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

    func saveWorkingContext(_ context: NSManagedObjectContext) {
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
