//
//  BlogEntryDetailView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 29.05.22.
//

import SwiftUI
import PopupView

struct BlogEntryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    
    private let persistence = PersistenceController.shared
    @EnvironmentObject private var fefeBlog: FefeBlogService
    @ObservedObject private var settings = Settings.shared
    
    @State private var showNotificationPopup = false
    @State private var showLoadingIndicator = false
    
    @State private var isSearching: Bool = false
    @State private var searchText: String = ""
    @State private var showSearchingIndicator = false
    
    @State private var showOnlyUnread = false
    @State private var showOnlyBookmarks = false
    
    @Binding var selectedBlogEntry: BlogEntry?
        
    private func loadOlderEntries() {
        ErrorService.shared.executeShowingError {
            print("Load older entries")
            showLoadingIndicator = true
            try await fefeBlog.loadOlderEntries()
            showLoadingIndicator = false
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            list
                .onChange(of: selectedBlogEntry) { entry in
                    if let entry {
                        proxy.scrollTo(entry.id)
                    }
                }
        }
    }
    
    private var list: some View {
        SearchableList(selection: _selectedBlogEntry, indicator: $isSearching) { isSearching in
            createListBody(validState: isSearching ? .search : .normal)
            if !isSearching && fefeBlog.canLoadMore {
                moreListEntriesAvailableView
            }
            if isSearching && showSearchingIndicator {
                searchingIndicator
            }
        }
        .listStyle(.plain)
        .navigationTitle("Fefes Blog")
        .onAppear {
            if Settings.shared.askForNotificationApproval {
                NotificationService.shared.checkExplicitAuthorization {
                    showNotificationPopup = true
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                if let id = NotificationService.shared.idToOpen, let entry = persistence.getBlogEntry(withId: Int(id), context: viewContext) {
                    NotificationService.shared.idToOpen = nil
                    selectedBlogEntry = entry
                }
            }
        }
        .refreshable {
            if !isSearching {
                await ErrorService.shared.executeShowingErrorAsync {
                    try await fefeBlog.refresh(origin: "manual refresh")
                }
            }
        }
        .searchable(text: $searchText)
        .disableAutocorrection(true)
        .onChange(of: isSearching) {
            if $0 {
                appPrint("yes")
            } else {
                appPrint("no")
            }
            /* TODO: if $0 {
                showSearchingIndicator = false
                DataAccess.shared.deleteSearchBlogEntries()
            } else {
                TaskService.shared.cancelTask(for: "search")
                Task {
                    DataAccess.shared.deleteSearchBlogEntries()
                }
            }*/
        }
        .onSubmit(of: .search) {
            search(for: searchText)
        }
        .popup(isPresented: $showNotificationPopup, type: .floater(verticalPadding: 10, useSafeAreaInset: true), position: .bottom, animation: .easeInOut, autohideIn: 10, closeOnTap: false) {
            notificationPopup
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    showOnlyBookmarks.toggle()
                }, label: {
                    CommonIcons.shared.bookmarkImage(active: showOnlyBookmarks)
                })
            }
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    showOnlyUnread.toggle()
                }, label: {
                    CommonIcons.shared.filterUnread(active: showOnlyUnread)
                })
            }
        }
    }
    
    private var moreListEntriesAvailableView: some View {
        HStack(alignment: .center) {
            if !showLoadingIndicator {
                Button(action: {
                    loadOlderEntries()
                }, label: {
                    Text("Ältere Einträge laden")
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(.bordered)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .listRowSeparator(.hidden)
        .onAppear {
            loadOlderEntries()
        }
    }
    
    private var searchingIndicator: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
    }
    
    private func createDynamicPredicate(validState: BlogEntry.ValidState) -> NSPredicate {
        var predicates = [NSPredicate]()
        predicates.append(NSPredicate(format: "validState = %@", validState.rawValue))
        if showOnlyUnread {
            predicates.append(NSPredicate(format: "readTimestamp = nil"))
        }
        if showOnlyBookmarks {
            predicates.append(NSPredicate(format: "bookmarkDate != nil"))
        }
        if predicates.count == 1 {
            return predicates.first!
        } else {
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
    }
    
    private func createListBody(validState: BlogEntry.ValidState) -> some View {
        SectionedFetchedObjectsView(
            sectionIdentifier: \BlogEntry.date,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \BlogEntry.date, ascending: false),
                NSSortDescriptor(keyPath: \BlogEntry.relativeNumber, ascending: false)
            ],
            predicate: createDynamicPredicate(validState: validState)
        ) { sectionedBlogEntries in
            ForEach(sectionedBlogEntries) { blogEntries in
                Section(blogEntries[0].secureDate.formatted(date: .long, time: .omitted)) {
                    ForEach(blogEntries) { blogEntry in
                        NavigationLink(value: blogEntry) {
                            BlogEntryRowView(blogEntry: blogEntry, tintReadEntries: !isSearching && settings.tintReadBlogentries)
                        }
                        .id(blogEntry.id)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button(action: {
                                withAnimation {
                                    persistence.toggleBlogEntryBookmark(blogEntry)
                                }
                            }, label: {
                                CommonIcons.shared.bookmarkImage()
                            })
                            .tint(CommonIcons.shared.bookmarkColor)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button(action: {
                                withAnimation {
                                    persistence.toggleBlogEntryRead(blogEntry)
                                }
                            }, label: {
                                Image(systemName: "app.badge")
                            })
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if true /*settings.enableDeletion*/ {
                                Button(action: {
                                    withAnimation {
                                        persistence.delete(blogEntry: blogEntry)
                                    }
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
    }
    
    private var notificationPopup: some View {
        VStack(spacing: 10) {
            Text("Möchtest Du benachrichtigt werden, wenn Fefe neue Blogeinträge veröffentlicht?")
                .font(.system(size: 16))
                .foregroundColor(.black)
            HStack {
                Button(action: {
                    Settings.shared.askForNotificationApproval = false
                    showNotificationPopup = false
                }, label: {
                    Text("Nein")
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                Button(action: {
                    Settings.shared.askForNotificationApproval = false
                    NotificationService.shared.requestAuthorizationExplicitly()
                    showNotificationPopup = false
                }, label: {
                    Text("Ja")
                    .frame(maxWidth: .infinity)
                })
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 0)
        .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 0)
        .padding(.horizontal, 16)
    }
    
    
    private func search(for searchString: String) {
        /*TODO: TaskService.shared.cancelTask(for: "search")
        appPrint("Searching for: \(searchString)")
        showSearchingIndicator = true
        let task = ErrorService.shared.executeShowingError {
            DataAccess.shared.deleteSearchBlogEntries()
            if !searchString.isEmpty {
                try await FefeBlogService.shared.search(for: searchString)
            }
            showLoadingIndicator = false
        }
        TaskService.shared.set(task: task, for: "search")*/
    }
}

struct BlogEntryListView_Previews: PreviewProvider {
    static var previews: some View {
        BlogEntryListView(selectedBlogEntry: .constant(nil))
            .environment(\.managedObjectContext, PreviewData.shared.container.viewContext)
            .environmentObject(FefeBlogService(context: PreviewData.shared.container.viewContext))
    }
}
