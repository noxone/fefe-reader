//
//  PreviewCoreDataStack.swift
//  FefeReader
//
//  Created by Olaf Neumann on 11.06.22.
//

import Foundation
import CoreData

class PreviewData {
    static let shared = PreviewData()
    
    private(set) var container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "FefeReader")
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        
        // Create data
        preview_internal_BlogEntries.append(preview_createBlogEntry(id: 1, teaser: "This is an unread teaser.", read: false, bookmark: false, temporary: false))
        preview_internal_BlogEntries.append(preview_createBlogEntry(id: 2, teaser: "This is another teaser, but read.", read: true, bookmark: false, temporary: false))
        preview_internal_BlogEntries.append(preview_createBlogEntry(id: 3, teaser: "Unread: This is some more text that is really long and does not fit into one single line.", read: false, bookmark: true, temporary: false))
        preview_internal_BlogEntries.append(preview_createBlogEntry(id: 4, teaser: "Read: And a fourth one... This one also has quite a long teaser text.", read: true, bookmark: false, temporary: false))
        preview_internal_BlogEntries[3].updatedSinceLastRead = true

        try! container.viewContext.save()
    }
    
    private var relNumber: Int = 0
    
    private func preview_createBlogEntry(id: Int, teaser: String, read: Bool, bookmark: Bool, temporary: Bool) -> BlogEntry {
        let blogEntry = BlogEntry(context: container.viewContext)
        blogEntry.validState = temporary ? BlogEntry.ValidState.temporary.rawValue : BlogEntry.ValidState.normal.rawValue
        blogEntry.id = Int64(id)
        blogEntry.relativeNumber = Int16(relNumber)
        relNumber += 1
        blogEntry.date = Date()
        blogEntry.content = "<html>ja, Beispiel-Content mit Link zu <a href=\"google.de\">Google</a><html>"
        blogEntry.bookmarkDate = bookmark ? Date() : nil
        blogEntry.teaser = teaser
        blogEntry.loadedTimestamp = Date()
        blogEntry.readTimestamp = nil
        return blogEntry
    }
    
    private var preview_internal_BlogEntries: [BlogEntry] = []
    var preview_BlogEntries: [BlogEntry] {
        get {
            preview_internal_BlogEntries
        }
    }
    
}
