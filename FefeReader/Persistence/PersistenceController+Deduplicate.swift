//
//  PersistenceController+Deduplicate.swift
//  FefeReader
//
//  Created by Olaf Neumann on 25.12.24.
//

import CoreData

extension PersistenceController {
    /**
     Deduplicate tags that have a same name and are in the same CloudKit record zone, one tag at a time, on the historyQueue.
     All peers should eventually reach the same result with no coordination or communication.
     */
    
    //#-code-listing(deduplicateAndWait)
    func deduplicateAndWait(blogEntryObjectIDs: [NSManagedObjectID])
    //#-end-code-listing
    {
        /**
         Make any store changes on a background context with the transaction author name of this app.
         Use performAndWait to serialize the steps. historyQueue runs in the background so this won’t block the main queue.
         */
        let taskContext = persistentContainer.newTaskContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        taskContext.performAndWait {
            blogEntryObjectIDs.forEach { blogEntryObjectID in
                deduplicate(blogEntryObjectID: blogEntryObjectID, performingContext: taskContext)
            }
            taskContext.save(with: .deduplicateAndWait)
        }
    }
    
    /**
     Deduplicate one single tag.
     */
    private func deduplicate(blogEntryObjectID: NSManagedObjectID, performingContext: NSManagedObjectContext) {
        guard let newBlogEntry = performingContext.object(with: blogEntryObjectID) as? BlogEntry else {
            // object does not exist
            return
        }
        
        let allBlogEntries = getBlogEntries(withIds: [newBlogEntry.id], context: performingContext)
        let oldestLoadedTimestamp = allBlogEntries.compactMap { $0.loadedTimestamp }
            .sorted(by: { lhs, rhs in lhs < rhs})
            .first
        let oldestBlogEntry = allBlogEntries.first(where: { $0.loadedTimestamp == oldestLoadedTimestamp })!
        let blogEntriesToDelete = allBlogEntries.filter { $0 != oldestBlogEntry }
        
        oldestBlogEntry.bookmarkDate = allBlogEntries.compactMap { $0.bookmarkDate }.first
        oldestBlogEntry.readTimestamp = allBlogEntries.compactMap { $0.readTimestamp }.first

        blogEntriesToDelete.forEach {
            performingContext.delete($0)
        }
    }
}
