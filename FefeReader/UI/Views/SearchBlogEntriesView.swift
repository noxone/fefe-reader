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
    
    @StateObject var textObserver = TextFieldObserver()
    @State private var searching = false
    
    @SectionedFetchRequest(
        entity: BlogEntry.entity(),
        sectionIdentifier: \BlogEntry.date,
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BlogEntry.date, ascending: false),
            NSSortDescriptor(keyPath: \BlogEntry.relativeNumber, ascending: true)
        ],
        predicate: NSPredicate(format: "validState = %@", BlogEntry.ValidState.search.rawValue),
        animation: .default)
    private var sectionedBlogEntries: SectionedFetchResults<Date?, BlogEntry>

    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    if !searching {
                        listContent
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .listRowSeparator(.hidden)
                    }
                }
                .searchable(text: $textObserver.searchText, placement: .navigationBarDrawer(displayMode: .always))
                .listStyle(.plain)
            }
            .navigationTitle("Suche")
        }
        .onChange(of: textObserver.debouncedText) {
            self.search(for: $0)
        }
        .onAppear {
            if textObserver.debouncedText.isEmpty {
                DataAccess.shared.deleteSearchBlogEntries()
            }
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
        searching = true
        ErrorService.shared.executeShowingError {
            DataAccess.shared.deleteSearchBlogEntries()
            if !searchString.isEmpty {
                try await FefeBlogService.shared.search(for: searchString)
            }
            searching = false
        }
    }
}

class TextFieldObserver : ObservableObject {
    @Published var debouncedText = ""
    @Published var searchText = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] t in
                self?.debouncedText = t
            } )
            .store(in: &subscriptions)
    }
}


struct SearchBlogEntriesView_Previews: PreviewProvider {
    static var previews: some View {
        SearchBlogEntriesView()
            .environment(\.managedObjectContext, PreviewData.shared.container.viewContext)
    }
}
