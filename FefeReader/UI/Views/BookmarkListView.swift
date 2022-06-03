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
            NSSortDescriptor(keyPath: \BlogEntry.date, ascending: false),
            NSSortDescriptor(keyPath: \BlogEntry.relativeNumber, ascending: true)
        ],
        predicate: NSPredicate(format: "favourite == %@", NSNumber(value: true)),
        animation: .default)
    private var blogEntries: FetchedResults<BlogEntry>

    var body: some View {
        NavigationView {
            List {
                ForEach(blogEntries) { blogEntry in
                    NavigationLink(destination: {
                        BlogEntryDetailView(blogEntry: blogEntry)
                    }, label: {
                        BlogEntryRowView(blogEntry: blogEntry, tintReadEntries: false, showBookmarkIcon: false)
                    })
                }
                if blogEntries.isEmpty {
                    Text("To add a bookmark, go to the blog tab and mark blog posts with the \(Image(systemName: CommonIcons.shared.bookmarkImageActiveName)) icon. These posts will be displayed here.")
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Bookmarks")
        }
    }
}

struct BookmarkListView_Previews: PreviewProvider {
    static var previews: some View {
        BookmarkListView()
    }
}
