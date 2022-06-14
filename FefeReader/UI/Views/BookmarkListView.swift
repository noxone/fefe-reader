//
//  BookmarkListView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 03.06.22.
//

import SwiftUI

struct BookmarkListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: BlogEntry.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BlogEntry.bookmarkDate, ascending: false),
            NSSortDescriptor(keyPath: \BlogEntry.relativeNumber, ascending: true)
        ],
        predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "validState = %@", BlogEntry.VALID_STATE_NORMAL),
            NSPredicate(format: "bookmarkDate != nil")
        ]),
        animation: .default)
    private var blogEntries: FetchedResults<BlogEntry>

    var body: some View {
        NavigationView {
            List {
                ForEach(blogEntries) { blogEntry in
                    NavigationLink {
                        BlogEntryDetailView(blogEntry: blogEntry)
                    } label: {
                        BlogEntryRowView(blogEntry: blogEntry, showDate: true, tintReadEntries: false, showBookmarkIcon: false, lineLimit: 4)
                    }
                }
                if blogEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Um ein Lesezeichen hinzuzufügen, öffne den \(CommonIcons.shared.blogImage) blog tab und markiere einen Blogeintrag mit dem Lesenzeichen \(CommonIcons.shared.bookmarkImage) Icon. Diese markierten Einträge werden dann hier angezeigt.")
                        Text("Um einen Blogeintrag als Lesezeichen zu markieren, wische in der Liste von links nach rechts. Alternativ kannst du einen Blogeintrag öffnen und in der Toolbar auf das Lesezeichen klicken.")
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Lesezeichen")
            // TODO: Show possibility to change sort direction
            /*.toolbar {
                ToolbarItem {
                    Button(action: {}, label: {
                        Image(systemName: "arrow.up.arrow.down")
                    })
                }
            }*/
        }
    }
}

struct BookmarkListView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkListView()
            .environment(\.managedObjectContext, PreviewData.shared.container.viewContext)
    }
}
