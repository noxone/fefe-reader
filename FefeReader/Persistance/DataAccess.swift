//
//  CoreDataAccess.swift
//  FefeReader
//
//  Created by Olaf Neumann on 10.06.22.
//

import Foundation
import CoreData

class DataAccess {
    static let shared = DataAccess()

    static let PREDICATE_VALID_STATE_NORMAL = NSPredicate(format: "validState = %@", BlogEntry.ValidState.normal.rawValue)

    private init() {}
    
    private let stack = CoreDataStack.shared
        
    func getBlogEntry(withId id: Int, onlyNormal: Bool = true) -> BlogEntry? {
        let request = BlogEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %ld", Int64(id))
        request.fetchLimit = 1
        if onlyNormal {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [request.predicate!, DataAccess.PREDICATE_VALID_STATE_NORMAL])
        }
        
        return try? stack.readForUi { try $0.fetch(request) }.first
    }
    
    func getOldestBlogEntry(includingBookmarks includeBookmarks: Bool = true) -> BlogEntry? {
        let request = BlogEntry.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BlogEntry.date, ascending: true)]
        request.predicate = DataAccess.PREDICATE_VALID_STATE_NORMAL
        if !includeBookmarks {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                request.predicate!,
                NSPredicate(format: "bookmarkDate == nil")
            ])
        }
        
        return try? stack.readForUi { try $0.fetch(request) }.first
    }
    
    func delete(object: NSManagedObject) {
        stack.with(context: object.managedObjectContext) { context in
            context.delete(object)
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
    
    func deleteSearchBlogEntries() {
        changeNonValidBlogEntries(withValidState: BlogEntry.ValidState.search) { $0.delete($1) }
    }
    
    func deleteTemporaryBlogEntries() {
        changeNonValidBlogEntries(withValidState: BlogEntry.ValidState.temporary) { $0.delete($1) }
    }

    private func changeNonValidBlogEntries(withValidState validState: BlogEntry.ValidState, callback: @escaping (NSManagedObjectContext, BlogEntry) -> ()) {
        stack.withWorkingContext { context in
            let request = BlogEntry.fetchRequest()
            request.predicate = NSPredicate(format: "validState == %@", validState.rawValue)
            if let entries = try? context.fetch(request) {
                entries.forEach {
                    callback(context, $0)
                }
                appPrint("Handled \(entries.count) temporary entries.")
            }
        }
    }
    
    func createUpdateFetch(from origin: String) {
        appPrint("Update from: \(origin)")
        /*let fetch = UpdateFetch(context: container.viewContext)
        fetch.date = Date()
        fetch.from = from
        save()*/
    }
    
    @discardableResult
    func createBlogEntry(from rawEntry: RawEntry, withValidState validState: BlogEntry.ValidState = .normal) -> BlogEntry {
        let preview = rawEntry.plainContent

        let blogEntry = BlogEntry(context: stack.managedObjectContext)
        blogEntry.validState = validState.rawValue
        blogEntry.id = Int64(rawEntry.id)
        blogEntry.relativeNumber = Int16(rawEntry.relativeNumber)
        blogEntry.date = rawEntry.date
        blogEntry.content = rawEntry.content
        blogEntry.bookmarkDate = nil
        blogEntry.teaser = preview
        blogEntry.loadedTimestamp = Date()
        blogEntry.readTimestamp = nil
        blogEntry.uuid = UUID()
        blogEntry.updatedSinceLastRead = false
        return blogEntry
    }
    
    func createTemporaryBlogEntry(from blogEntry: BlogEntry) -> BlogEntry {
        return stack.withMainContext { context in
            let blogEntry = BlogEntry(context: context)
            blogEntry.validState = BlogEntry.ValidState.temporary.rawValue
            blogEntry.id = blogEntry.id
            blogEntry.relativeNumber = blogEntry.relativeNumber
            blogEntry.date = blogEntry.date
            blogEntry.content = blogEntry.content
            blogEntry.bookmarkDate = blogEntry.bookmarkDate
            blogEntry.teaser = blogEntry.teaser
            blogEntry.loadedTimestamp = blogEntry.loadedTimestamp
            blogEntry.readTimestamp = blogEntry.readTimestamp
            blogEntry.uuid = UUID()
            return blogEntry
        }
    }
    
    // TODO: https://code.tutsplus.com/tutorials/core-data-and-swift-batch-updates--cms-25120
    func resetBookmarks() {
        stack.withWorkingContext { context in
            do {
                let request = BlogEntry.fetchRequest()
                _ = (\BlogEntry.bookmarkDate) // Reminder, that "bookmarkDate" is used here
                request.predicate = NSPredicate(format: "bookmarkDate != nil")
                
                let entries = try context.fetch(request)
                entries.forEach {
                    $0.bookmarkDate = nil
                }
            } catch {
                // TODO: Properly handle error
                print("Error resetting bookmarks.", error)
            }
        }
    }
    
    func resetRead() {
        stack.withWorkingContext { context in
            do {
                let request = BlogEntry.fetchRequest()
                _ = (\BlogEntry.readTimestamp) // Reminder, that "readTimestamp" is used here
                request.predicate = NSPredicate(format: "readTimestamp != nil")
                
                let entries = try context.fetch(request)
                entries.forEach {
                    $0.readTimestamp = nil
                }
            } catch {
                // TODO: Properly handle error
                print("Error resetting read state.", error)
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
