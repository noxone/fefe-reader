//
//  BlogEntryDetailView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 29.05.22.
//

import SwiftUI

struct BlogEntryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var fefeBlog = FefeBlog.shared
    
    @SectionedFetchRequest(
        entity: BlogEntry.entity(),
        sectionIdentifier: \BlogEntry.date,
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BlogEntry.date, ascending: false),
            NSSortDescriptor(keyPath: \BlogEntry.relativeNumber, ascending: true)
        ],
        animation: .default)
    private var sectionedBlogEntries: SectionedFetchResults<Date?, BlogEntry>

    var body: some View {
        NavigationView {
            List {
                listContent
                if fefeBlog.canLoadMore {
                    Text("... end of list ...")
                        .italic()
                        .onAppear {
                            print("Load older entries")
                            fefeBlog.loadOlderEntries()
                        }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Fefes Blog")
            .refreshable {
                _ = FefeBlog.shared.refresh(origin: "manual refresh")
            }
        }
    }
    
    private var listContent: some View {
        ForEach(sectionedBlogEntries) { blogEntries in
            Section(blogEntries[0].secureDate.formatted(date: .long, time: .omitted)) {
                ForEach(blogEntries) { blogEntry in
                    NavigationLink {
                        BlogEntryDetailView(blogEntry: blogEntry)
                    } label: {
                        BlogEntryRowView(blogEntry: blogEntry)
                            .badge(blogEntry.updatedSinceLastRead ? Text("Updates") : nil)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
                        Button(action: {
                            fefeBlog.toggleBookmark(for: blogEntry)
                        }, label: {
                            CommonIcons.shared.bookmarkImage()
                        })
                        .tint(CommonIcons.shared.bookmarkColor)
                    })
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(action: {
                            PersistenceController.shared.delete(blogEntry: blogEntry)
                        }, label: {
                            CommonIcons.shared.trashImage
                        })
                        .tint(.red)
                    }
                }
            }
        }
    }
}

struct BlogEntryListView_Previews: PreviewProvider {
    static var previews: some View {
        BlogEntryListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
