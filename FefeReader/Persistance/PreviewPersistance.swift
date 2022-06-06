//
//  PreviewPersistance.swift
//  FefeReader
//
//  Created by Olaf Neumann on 30.05.22.
//

import Foundation
import CoreData

extension PersistenceController {
    private static var relNumber: Int = 0
    
    private func preview_createBlogEntry(id: Int, teaser: String, read: Bool, bookmark: Bool) -> BlogEntry {
        let entry = BlogEntry(context: container.viewContext)
        entry.id = Int64(id)
        entry.date = Date()
        entry.relativeNumber = Int16(PersistenceController.relNumber)
        PersistenceController.relNumber += 1
        entry.teaser = teaser
        if read {
            entry.readTimestamp = Date()
        }
        entry.bookmarkDate = bookmark ? Date() : nil
        entry.content = "<html>ja, <a href=\"google.de\">Google</a><html>"
        return entry
    }
    
    private func preview_createUpdate(from: String) -> UpdateFetch {
        let update = UpdateFetch(context: container.viewContext)
        update.date = Date()
        update.from = from
        return update
    }
    
    private static var preview_internal_BlogEntries: [BlogEntry] = []
    var preview_BlogEntries: [BlogEntry] {
        get {
            PersistenceController.preview_internal_BlogEntries
        }
    }
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        preview_internal_BlogEntries.append(result.preview_createBlogEntry(id: 1, teaser: "This is an unread teaser.", read: false, bookmark: false))
        preview_internal_BlogEntries.append(result.preview_createBlogEntry(id: 2, teaser: "This is another teaser, but read.", read: true, bookmark: false))
        preview_internal_BlogEntries.append(result.preview_createBlogEntry(id: 3, teaser: "Unread: This is some more text that is really long and does not fit into one single line.", read: false, bookmark: true))
        preview_internal_BlogEntries.append(result.preview_createBlogEntry(id: 4, teaser: "Read: And a fourth one... This one also has quite a long teaser text.", read: true, bookmark: false))
        preview_internal_BlogEntries[3].updatedSinceLastRead = true

        _ = result.preview_createUpdate(from: "a")
        _ = result.preview_createUpdate(from: "b")
        _ = result.preview_createUpdate(from: "c")

        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

}
