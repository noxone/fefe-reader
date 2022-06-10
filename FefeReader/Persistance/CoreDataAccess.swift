//
//  CoreDataAccess.swift
//  FefeReader
//
//  Created by Olaf Neumann on 10.06.22.
//

import Foundation
import CoreData

class CoreDataAccess {
    static let shared = CoreDataAccess()

    static let PREDICATE_VALID_STATE_NORMAL = NSPredicate(format: "validState = %@", BlogEntry.VALID_STATE_NORMAL)

    private init() {}
    
    let stack = CoreDataStack.shared
        
    func getBlogEntry(withId id: Int, onlyNormal: Bool = true) -> BlogEntry? {
        let request = BlogEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %ld", Int64(id))
        request.fetchLimit = 1
        if onlyNormal {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [request.predicate!, PersistenceController.PREDICATE_VALID_STATE_NORMAL])
        }
        
        return try? stack.managedObjectContext.fetch(request).first
    }
    
    func getOldestBlogEntry() -> BlogEntry? {
        let request = BlogEntry.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BlogEntry.date, ascending: true)]
        request.predicate = PersistenceController.PREDICATE_VALID_STATE_NORMAL
        
        return try? stack.managedObjectContext.fetch(request).first
    }
    
    func delete(blogEntry: BlogEntry) {
        CoreDataStack.shared.withMainContext { context in
            context.delete(blogEntry)
        }
    }
    
    func deleteBlogEntries(olderThan date: Date, keepingBookmarks keepBookmarks: Bool) {
        stack.withWorkingContext { context in
            let request = BlogEntry.fetchRequest()
            let startOfMonth = date.startOfMonth
            request.predicate = NSPredicate(format: "date < %@", (startOfMonth) as NSDate)
            if keepBookmarks {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    request.predicate!,
                    NSPredicate(format: "bookmarkDate == nil")
                ])
            }
            if let entries = try? context.fetch(request) {
                print("Deleting entries: ", entries.count)
                for entry in entries {
                    context.delete(entry)
                }
            }
        }
    }
    
    func deleteTemporaryBlogEntries() {
        changeNonValidBlogEntries { $0.delete($1) }
    }

    private func changeNonValidBlogEntries(callback: @escaping (NSManagedObjectContext, BlogEntry) -> ()) {
        stack.withWorkingContext { context in
            let request = BlogEntry.fetchRequest()
            request.predicate = NSPredicate(format: "validState == %@", BlogEntry.VALID_STATE_TEMPORARY)
            if let entries = try? context.fetch(request) {
                for entry in entries {
                    callback(context, entry)
                }
                appPrint("Handled \(entries.count) temporary entries.")
            }
        }
    }
    
    func createUpdateFetch(from: String) {
        /*let fetch = UpdateFetch(context: container.viewContext)
        fetch.date = Date()
        fetch.from = from
        save()*/
    }
    
    func createBlogEntry(context: NSManagedObjectContext, from rawEntry: RawEntry, temporary: Bool = false) -> BlogEntry {
        let blogEntry = BlogEntry(context: context)
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
    
    /*func delete(blogEntry: BlogEntry) {
        container.viewContext.delete(blogEntry)
        save()
    }*/
    
    // TODO: https://code.tutsplus.com/tutorials/core-data-and-swift-batch-updates--cms-25120
    func resetBookmarks() {
        stack.withWorkingContext { context in
            do {
                let request = BlogEntry.fetchRequest()
                _ = (\BlogEntry.isBookmarked) // Reminder, that "isBookmarked" is used here
                request.predicate = NSPredicate(format: "bookmarkDate != nil")
                
                let entries = try context.fetch(request)
                for entry in entries {
                    entry.bookmarkDate = nil
                }
            } catch {
                // TODO: Properly handle error
                print("Error resetting bookmarks.", error)
            }
        }
    }
    
    // TODO: https://www.advancedswift.com/batch-delete-everything-core-data-swift/
    // TODO: Regularly clear temporary items
    func clearBlogEntries() {
        stack.withWorkingContext { context in
            do {
                let request = BlogEntry.fetchRequest()
                let items = try context.fetch(request)
                for item in items {
                    context.delete(item)
                }
            } catch {
                // TODO: Properly handle error
                // TODO: replace by log
                print("Error deleting data.", error)
            }
        }
    }
    
    func cleanUpDatabase(deleteOldBlogEntries: Bool, keepBookmarks: Bool) {
        deleteTemporaryBlogEntries()
        if deleteOldBlogEntries {
            let halfAYearAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
            deleteBlogEntries(olderThan: halfAYearAgo, keepingBookmarks: keepBookmarks)
        }
    }
}
