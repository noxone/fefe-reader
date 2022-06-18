//
//  SearchBlogEntriesView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 17.06.22.
//

import SwiftUI
import Combine

struct SearchBlogEntriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @SectionedFetchRequest(
        sectionIdentifier: \BlogEntry.date,
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BlogEntry.date, ascending: false),
            NSSortDescriptor(keyPath: \BlogEntry.relativeNumber, ascending: true)
        ],
        predicate: NSPredicate(format: "validState = %@", BlogEntry.ValidState.search.rawValue),
        animation: .default)
    private var sectionedBlogEntries: SectionedFetchResults<Date?, BlogEntry>
    
    @ObservedObject private var searchText = TextDebouncer()
    @State private var showSearchingIndicator = false

    var body: some View {
        NavigationView {
            List {
                listContent
                if showSearchingIndicator {
                    ProgressView()
                        .listRowSeparator(.hidden)
                        .frame(maxWidth: .infinity)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText.searchText)
            .disableAutocorrection(true)
            .navigationTitle("Suche")
            .onChange(of: searchText.debouncedText) { search(for: $0) }
        }
    }
    
    private var listContent: some View {
        ForEach(sectionedBlogEntries) { blogEntries in
            Section(blogEntries[0].secureDate.formatted(date: .long, time: .omitted)) {
                ForEach(blogEntries) { blogEntry in
                    NavigationLink(destination: {
                        BlogEntryDetailView(blogEntry: blogEntry)
                    }, label: {
                        BlogEntryRowView(blogEntry: blogEntry, tintReadEntries: false, showBookmarkIcon: false)
                    })
                }
            }
        }
    }
    
    private func search(for searchString: String) {
        showSearchingIndicator = true
        ErrorService.shared.executeShowingError {
            DataAccess.shared.deleteSearchBlogEntries()
            if !searchString.isEmpty {
                try await FefeBlogService.shared.search(for: searchString)
            }
            showSearchingIndicator = false
        }
    }
}

struct SearchBlogEntriesView_Previews: PreviewProvider {
    static var previews: some View {
        SearchBlogEntriesView()
            .environment(\.managedObjectContext, PreviewData.shared.container.viewContext)
    }
}
