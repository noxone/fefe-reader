//
//  PersistenseController.swift
//  FefeReader
//
//  Created by Olaf Neumann on 26.11.24.
//

import Foundation
import CoreData

private let gCloudKitContainerIdentifier = "iCloud.org.olafneumann.FefeBlogReader"

extension PersistenceController {
    func createBlogEntryAndSave(from rawEntry: RawEntry, withValidState validState: BlogEntry.ValidState, context: NSManagedObjectContext) -> BlogEntry {
        let blogEntry = createBlogEntry(from: rawEntry, withValidState: validState, context: context)
        context.save(with: .addBlogEntry)
        return blogEntry
    }
    
    private func createBlogEntry(from rawEntry: RawEntry, withValidState validState: BlogEntry.ValidState, context: NSManagedObjectContext) -> BlogEntry {
        let blogEntry = BlogEntry(context: context)
        blogEntry.validState = validState.rawValue
        blogEntry.id = Int64(rawEntry.id)
        blogEntry.relativeNumber = Int16(rawEntry.relativeNumber)
        blogEntry.date = rawEntry.date
        blogEntry.content = rawEntry.content
        blogEntry.bookmarkDate = nil
        blogEntry.teaser = rawEntry.plainContent
        blogEntry.loadedTimestamp = Date()
        blogEntry.readTimestamp = nil
        blogEntry.updatedSinceLastRead = false
        return blogEntry
    }
    
    func createOrUpdateBlogEntries(from rawEntries: [RawEntry], validState: BlogEntry.ValidState, context: NSManagedObjectContext) async throws -> [BlogEntry] {
        return try await context.perform {
            appPrint("Reading existing entries...")
            let readEntries = self.getBlogEntries(withIds: rawEntries.map {Int64($0.id)}, context: context).reduce(into: [Int64: BlogEntry]()) { array, item in
                array[item.id] = item
            }
            appPrint("Found \(readEntries.count) existing entries in database.")
            appPrint("Persisting \(rawEntries.count) entries to database...")
            var updatedBlogEntryCount: Int = 0
            var createdBlogEntryCount: Int = 0
            var createdBlogEntries: [BlogEntry] = []
            
            for rawEntry in rawEntries {
                guard !Task.isCancelled else {
                    appPrint("Cancelled task!")
                    throw FefeBlogError.cancelled
                }
                
                if let blogEntry = readEntries[Int64(rawEntry.id)] {
                    var updated = false
                    // Update content
                    if blogEntry.content != rawEntry.content {
                        blogEntry.content = rawEntry.content
                        blogEntry.teaser = rawEntry.plainContent
                        if blogEntry.isRead {
                            blogEntry.updatedSinceLastRead = true
                        }
                        updated = true
                    }
                    if blogEntry.relativeNumber != rawEntry.relativeNumber {
                        blogEntry.relativeNumber = Int16(rawEntry.relativeNumber)
                        updated = true
                    }
                    if updated {
                        updatedBlogEntryCount += 1
                    }
                } else {
                    // Create entry
                    let newBlogEntry = self.createBlogEntry(from: rawEntry, withValidState: validState, context: context)
                    createdBlogEntries.append(newBlogEntry)
                    createdBlogEntryCount += 1
                }
            }
            context.save(with: .addBlogEntry)
            appPrint("Entries: \(rawEntries.count), updated: \(updatedBlogEntryCount); created \(createdBlogEntryCount)")
            return createdBlogEntries
        }
    }
    
    func countBlogEntries(context: NSManagedObjectContext) -> Int {
        let request = BlogEntry.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }
    
    func getBlogEntry(withId id: Int, context: NSManagedObjectContext) -> BlogEntry? {
        let request = BlogEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %ld", Int64(id))
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }

    
    private func getBlogEntries(withIds ids: [Int64], context: NSManagedObjectContext) -> [BlogEntry] {
        let request = BlogEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids)
        
        return (try? context.fetch(request)) ?? []
    }
    
    func countBlogEntriesThatAreUnreadAndNewer(than date: Date, context: NSManagedObjectContext) -> Int {
        let request = BlogEntry.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", #keyPath(BlogEntry.validState), BlogEntry.ValidState.normal.rawValue),
            NSPredicate(format: "%K == nil", #keyPath(BlogEntry.readTimestamp)),
            NSPredicate(format: "%K > %@", #keyPath(BlogEntry.loadedTimestamp), date as NSDate)
            ])
        return (try? context.count(for: request)) ?? 0
    }
    
    func getOldestBlogEntry(context: NSManagedObjectContext) -> BlogEntry? {
        let request = BlogEntry.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BlogEntry.date, ascending: true)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", #keyPath(BlogEntry.validState), BlogEntry.ValidState.normal.rawValue),
            NSPredicate(format: "%K == nil", #keyPath(BlogEntry.bookmarkDate))
        ])
        
        return try? context.fetch(request).first
    }
    
    func getYoungestBlogEntry(olderThan date: Date, context: NSManagedObjectContext) -> BlogEntry? {
        let request = BlogEntry.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BlogEntry.date, ascending: false)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", #keyPath(BlogEntry.validState), BlogEntry.ValidState.normal.rawValue),
            NSPredicate(format: "date < %@", date as NSDate)
        ])
        
        return try? context.fetch(request).first
    }
    
    func getPreviousBlogEntry(from blogEntry: BlogEntry, context: NSManagedObjectContext) -> BlogEntry? {
        return getCloseBlogEntry(from: blogEntry, sortingAscending: false, context: context)
    }
    
    func getNextBlogEntry(from blogEntry: BlogEntry, context: NSManagedObjectContext) -> BlogEntry? {
        return getCloseBlogEntry(from: blogEntry, sortingAscending: true, context: context)
    }
    
    private func getCloseBlogEntry(from blogEntry: BlogEntry, sortingAscending ascending: Bool, context: NSManagedObjectContext) -> BlogEntry? {
        let request = BlogEntry.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \BlogEntry.date, ascending: !ascending),
            NSSortDescriptor(keyPath: \BlogEntry.relativeNumber, ascending: !ascending)
        ]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "%K == %@", #keyPath(BlogEntry.validState), BlogEntry.ValidState.normal.rawValue),
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                ascending ? NSPredicate(format: "date < %@", blogEntry.secureDate as NSDate) : NSPredicate(format: "date > %@", blogEntry.secureDate as NSDate),
                NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "date = %@", blogEntry.secureDate as NSDate),
                    ascending ? NSPredicate(format: "relativeNumber < %i", blogEntry.relativeNumber) : NSPredicate(format: "relativeNumber > %i", blogEntry.relativeNumber)
                ])
            ])
        ])
        return try? context.fetch(request).first
    }
    
    func toggleBlogEntryRead(_ blogEntry: BlogEntry, read: Bool? = nil) {
        if let context = blogEntry.managedObjectContext {
            context.perform {
                let willBeRead = read ?? !blogEntry.isRead
                blogEntry.readTimestamp = willBeRead ? Date() : nil
                blogEntry.updatedSinceLastRead = false
                
                context.save(with: .updateBlogEntry)
            }
        }
    }
    
    func toggleBlogEntryBookmark(_ blogEntry: BlogEntry) {
        if let context = blogEntry.managedObjectContext {
            context.perform {
                let willBeBookmarked = !blogEntry.isBookmarked
                blogEntry.bookmarkDate = willBeBookmarked ? Date() : nil
                if willBeBookmarked {
                    blogEntry.validState = BlogEntry.ValidState.normal.rawValue
                }
                
                context.save(with: .updateBlogEntry)
            }
        }
    }
    
    func updateBlogEntry_resetAllReadTimestamps(context: NSManagedObjectContext) async {
        do {
            let count = try await updateBlogEntry(
                withPredicate: NSPredicate(format: "%K != nil", #keyPath(BlogEntry.readTimestamp)),
                propertiesToUpdate: [#keyPath(BlogEntry.readTimestamp): NSExpression(forConstantValue: nil)],
                context: context
            )
            appPrint("Reset \(count) blog entries' read timestamps")
        } catch {
            appPrint("Error updating blog entries: \(error)")
        }
    }
    
    func updateBlogEntry_resetAllBookmarkTimestamps(context: NSManagedObjectContext) async {
        do {
            let count = try await updateBlogEntry(
                withPredicate: NSPredicate(format: "%K != nil", #keyPath(BlogEntry.bookmarkDate)),
                propertiesToUpdate: [#keyPath(BlogEntry.bookmarkDate): NSExpression(forConstantValue: nil)],
                context: context
            )
            appPrint("Reset \(count) blog entries' bookmark timestamps")
        } catch {
            appPrint("Error updating blog entries: \(error)")
        }
    }
    
    private func updateBlogEntry(withPredicate predicate: NSPredicate? = nil, propertiesToUpdate: [AnyHashable: Any], context: NSManagedObjectContext) async throws -> Int {
        // MAYBE: newBackgroundContext
        
        return try await context.perform {
            // Create NSBatchUpdateRequest and set the corresponding entity
            let batchUpdateRequest = NSBatchUpdateRequest(entity: BlogEntry.entity())
            batchUpdateRequest.resultType = .updatedObjectIDsResultType
            if let predicate {
                batchUpdateRequest.predicate = predicate
            }
            // Set the result return type, which returns all changed records' NSManagedObjectID in this example
            batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
            
            // Perform batch operation
            let result = try context.execute(batchUpdateRequest) as! NSBatchUpdateResult
            let changes: [AnyHashable: Any] = [NSUpdatedObjectsKey: result.result as! [NSManagedObjectID]]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            context.save(with: .updateBlogEntry)
            return (changes["updated"] as! [Any]).count
        }
    }
    
    func delete(blogEntry: BlogEntry) {
        if let context = blogEntry.managedObjectContext {
            context.perform {
                context.delete(blogEntry)
                context.save(with: .deleteBlogEntry)
            }
        }
    }
    
    private func deleteBlogEntry(predicate: NSPredicate, context: NSManagedObjectContext) async -> Int {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult>
        fetchRequest = BlogEntry.fetchRequest()
        fetchRequest.predicate = predicate
        do {
            let count = try await delete(byFetch: fetchRequest, context: context)
            appPrint("Deleted \(count) blog entries with predicate.")
            return count
        } catch {
            appPrint("Error deleting blog entries: \(error)")
            return 0
        }
    }
    
    private func delete(byFetch fetchRequest: NSFetchRequest<NSFetchRequestResult>, context: NSManagedObjectContext) async throws -> Int {
        return try await context.perform {
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            let result = try context.execute(batchDeleteRequest) as! NSBatchDeleteResult
            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: result.result as! [NSManagedObjectID]
            ]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            context.save(with: .deleteBlogEntry)
            
            return (changes["deleted"] as! [Any]).count
        }
    }
    
    func deleteOldBlogEntries(butKeepBookmarks keepBookmarks: Bool, context: NSManagedObjectContext) async -> Int {
        let halfAYearAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        return await deleteBlogEntries(olderThan: halfAYearAgo, keepingBookmarks: keepBookmarks, context: context)
    }
    
    func deleteAllBlogEntries(context: NSManagedObjectContext) async {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult>
        fetchRequest = BlogEntry.fetchRequest()
        do {
            let count = try await delete(byFetch: fetchRequest, context: context)
            appPrint("Deleted all \(count) blog entries.")
        } catch {
            appPrint("Error deleting all blog entries", error)
        }
    }
    
    private func deleteBlogEntries(olderThan date: Date, keepingBookmarks keepBookmarks: Bool, context: NSManagedObjectContext) async -> Int {
        let request: NSFetchRequest<any NSFetchRequestResult>
        request = BlogEntry.fetchRequest()
        let startOfMonth = date.startOfMonth
        request.predicate = NSPredicate(format: "%K < %@", #keyPath(BlogEntry.date), (startOfMonth) as NSDate)
        if keepBookmarks {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                request.predicate!,
                NSPredicate(format: "%K == nil", #keyPath(BlogEntry.bookmarkDate))
            ])
        }
        do {
            let count = try await delete(byFetch: request, context: context)
            appPrint("Deleted \(count) blog entries older than \(date).")
            return count
        } catch {
            appPrint("Error deleting blog entries older than \(date)", error)
            return 0
        }
    }
    
    func deleteBlogEntriesForSearch(context: NSManagedObjectContext) async {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult>
        fetchRequest = BlogEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(BlogEntry.validState), BlogEntry.ValidState.search.rawValue)

        do {
            let count = try await delete(byFetch: fetchRequest, context: context)
            appPrint("Deleted \(count) blog entries for search.")
        } catch {
            appPrint("Error deleting blog entries for search", error)
        }
    }
}
