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
    
    @ObservedObject var fefeBlog = FefeBlogService.shared
    @ObservedObject var settings = Settings.shared
    
    @Binding var tabSelection: TabbedBlogView.TabItem
    
    @State private var selectedBlogEntry: BlogEntry? = nil
    
    @State private var showNotificationPopup = false
    @State private var showLoadingIndicator = false
    
    @State private var isSearching: Bool = false
    @State private var searchText: String = ""
    @State private var showSearchingIndicator = false
        
    private func loadOlderEntries() {
        ErrorService.shared.executeShowingError {
            print("Load older entries")
            showLoadingIndicator = true
            try await fefeBlog.loadOlderEntries()
            showLoadingIndicator = false
        }
    }
    
    var body: some View {
        NavigationView {
            SearchableList(indicator: $isSearching) { isSearching in
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
                    if let id = NotificationService.shared.idToOpen, let entry = DataAccess.shared.getBlogEntry(withId: Int(id)) {
                        NotificationService.shared.idToOpen = nil
                        selectedBlogEntry = entry
                        tabSelection = .blog
                    }
                }
            }
            .refreshable {
                if !isSearching {
                    await ErrorService.shared.executeShowingErrorAsync {
                        try await FefeBlogService.shared.refresh(origin: "manual refresh")
                    }
                }
            }
            .searchable(text: $searchText)
            .disableAutocorrection(true)
            .onChange(of: isSearching) {
                if $0 {
                    showSearchingIndicator = false
                    DataAccess.shared.deleteSearchBlogEntries()
                } else {
                    TaskService.shared.cancelTask(for: "search")
                    Task {
                        DataAccess.shared.deleteSearchBlogEntries()
                    }
                }
            }
            .onSubmit(of: .search) {
                search(for: searchText)
            }
            .popup(isPresented: $showNotificationPopup, type: .floater(verticalPadding: 10, useSafeAreaInset: true), position: .bottom, animation: .easeInOut, autohideIn: 10, closeOnTap: false) {
                notificationPopup
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
    
    private func createListBody(validState: BlogEntry.ValidState) -> some View {
        SectionedFetchedObjectsView(
            sectionIdentifier: \BlogEntry.date,
            sortDescriptors: [
                NSSortDescriptor(keyPath: \BlogEntry.date, ascending: false),
                NSSortDescriptor(keyPath: \BlogEntry.relativeNumber, ascending: true)
            ],
            predicate: NSPredicate(format: "validState = %@", validState.rawValue)
        ) { sectionedBlogEntries in
            ForEach(sectionedBlogEntries) { blogEntries in
                Section(blogEntries[0].secureDate.formatted(date: .long, time: .omitted)) {
                    ForEach(blogEntries) { blogEntry in
                        NavigationLink(tag: blogEntry, selection: $selectedBlogEntry) {
                            BlogEntryDetailView(blogEntry: blogEntry)
                        } label: {
                            BlogEntryRowView(blogEntry: blogEntry, tintReadEntries: !isSearching && settings.tintReadBlogentries)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true, content: {
                            Button(action: {
                                fefeBlog.toggleBookmark(for: blogEntry)
                            }, label: {
                                CommonIcons.shared.bookmarkImage()
                            })
                            .tint(CommonIcons.shared.bookmarkColor)
                        })
                        /*.swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(action: {
                                DataAccess.shared.delete(object: blogEntry)
                            }, label: {
                                CommonIcons.shared.trashImage
                            })
                            .tint(.red)
                        }*/
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button(action: {
                                fefeBlog.toggleRead(blogEntry)
                            }, label: {
                                Image(systemName: "app.badge")
                            })
                            .tint(.blue)
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
        TaskService.shared.cancelTask(for: "search")
        appPrint("Searching for: \(searchString)")
        showSearchingIndicator = true
        let task = ErrorService.shared.executeShowingError {
            DataAccess.shared.deleteSearchBlogEntries()
            if !searchString.isEmpty {
                try await FefeBlogService.shared.search(for: searchString)
            }
            showLoadingIndicator = false
        }
        TaskService.shared.set(task: task, for: "search")
    }
}

struct BlogEntryListView_Previews: PreviewProvider {
    static var previews: some View {
        BlogEntryListView(tabSelection: .constant(.blog))
            .environment(\.managedObjectContext, PreviewData.shared.container.viewContext)
    }
}
