//
//  Persistence.swift
//  FefeReader
//
//  Created by Olaf Neumann on 29.05.22.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FefeReader")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    static func defaultCompletionHandler(error: Error?) {
        if let error = error {
            print("PERSISTANCE ERROR: " + error.localizedDescription)
        }
    }
    
    func save(onComplete completion: @escaping (Error?) -> () = defaultCompletionHandler) {
        if container.viewContext.hasChanges {
            container.viewContext.saveOrRollback(onComplete: completion)
        }
    }
    
    static let PREDICATE_VALID_STATE_NORMAL = NSPredicate(format: "validState = %@", BlogEntry.VALID_STATE_NORMAL)
    
    func getBlogEntry(withId id: Int, onlyNormal: Bool = false) -> BlogEntry? {
        let request = BlogEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %ld", Int64(id))
        request.fetchLimit = 1
        if onlyNormal {
            request.predicate = PersistenceController.PREDICATE_VALID_STATE_NORMAL
        }
        
        return try? container.viewContext.fetch(request).first
    }
    
    func getOldestBlogEntry() -> BlogEntry? {
        let request = BlogEntry.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BlogEntry.date, ascending: true)]
        request.predicate = PersistenceController.PREDICATE_VALID_STATE_NORMAL
        
        return try? container.viewContext.fetch(request).first
    }
    
    func changeNonValidBlogEntries(callback: @escaping (BlogEntry) -> ()) {
        let request = BlogEntry.fetchRequest()
        request.predicate = NSPredicate(format: "validState == nil")
        if let entries = try? container.viewContext.fetch(request) {
            for entry in entries {
                callback(entry)
            }
            save()
        }
    }
    
    func createUpdateFetch(from: String) {
        let fetch = UpdateFetch(context: container.viewContext)
        fetch.date = Date()
        fetch.from = from
        save()
    }
    
    func createBlogEntry(from rawEntry: RawEntry, temporary: Bool = false) -> BlogEntry {
        let blogEntry = BlogEntry(context: container.viewContext)
        blogEntry.validState = temporary ? BlogEntry.VALID_STATE_TEMPORARY : BlogEntry.VALID_STATE_NORMAL
        blogEntry.id = Int64(rawEntry.id)
        blogEntry.relativeNumber = Int16(rawEntry.relativeNumber)
        blogEntry.date = rawEntry.date
        blogEntry.content = rawEntry.content
        blogEntry.bookmarkDate = nil
        let preview = rawEntry.plainContent
        blogEntry.teaser = preview
        blogEntry.loadedTimestamp = Date()
        blogEntry.readTimestamp = nil
        blogEntry.uuid = UUID()
        return blogEntry
    }
    
    func delete(blogEntry: BlogEntry) {
        container.viewContext.delete(blogEntry)
        save()
    }
    
    // TODO: https://code.tutsplus.com/tutorials/core-data-and-swift-batch-updates--cms-25120
    func resetBookmarks() {
        do {
            let request = BlogEntry.fetchRequest()
            _ = (\BlogEntry.isBookmarked) // Reminder, that "isBookmarked" is used here
            request.predicate = NSPredicate(format: "bookmarkDate != nil")
            
            let entries = try container.viewContext.fetch(request)
            for entry in entries {
                entry.bookmarkDate = nil
            }

            save()
        } catch {
            // TODO: Properly handle error
            print("Error resetting bookmarks.", error)
        }
    }
    
    // TODO: https://www.advancedswift.com/batch-delete-everything-core-data-swift/
    // TODO: Regularly clear temporary items
    func clearBlogEntries() {
        do {
            let request = BlogEntry.fetchRequest()
            let items = try container.viewContext.fetch(request)
            for item in items {
                container.viewContext.delete(item)
            }
            save()
        } catch {
            // TODO: Properly handle error
            // TODO: replace by log
            print("Error deleting data.", error)
        }
    }
}

// https://github.com/donnywals/HomeTasks/blob/main/HomeTasks/Storage/ManagedObjectContext.swift
extension NSManagedObjectContext {
    func saveOrRollback(onComplete completion: @escaping (Error?) -> ()) {
        guard hasChanges else {
            return
        }

        do {
            try save()
            completion(nil)
        } catch {
            rollback()
            print(error)
            completion(error)
        }
    }
}

