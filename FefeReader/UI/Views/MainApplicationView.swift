//
//  TabbedBlogView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.06.22.
//

import SwiftUI

struct MainApplicationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var errorService = ErrorService.shared
    
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    
    @State private var currentBlogEntry: BlogEntry?
    @State private var subBlogEntries = [BlogEntry]()
    
    @State private var showSettingsSheet: Bool = false
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont(name: "Allison", size: 55)!]
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            BlogEntryListView(selectedBlogEntry: $currentBlogEntry)
                .environment(\.managedObjectContext, viewContext)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            showSettingsSheet.toggle()
                        }, label: {
                            CommonIcons.shared.settingsImage
                        })
                    }
                }
        } detail: {
            let navigateToEntry: (BlogEntry) -> Void = { currentBlogEntry = $0 }
            let navigateToSubEntry: (BlogEntry) -> Void = { subBlogEntries.append($0) }
            NavigationStack(path: $subBlogEntries) {
                if let currentBlogEntry {
                    BlogEntryDetailView(blogEntry: currentBlogEntry, navigateToEntry: navigateToEntry, navigateToSubEntry: navigateToSubEntry)
                        .environment(\.managedObjectContext, viewContext)
                } else {
                    Text("Kein Blogeintrag zum Lesen ausgewählt.")
                }
            }
            .navigationDestination(for: BlogEntry.self) { blogEntry in
                BlogEntryDetailView(blogEntry: blogEntry, navigateToEntry: nil, navigateToSubEntry: navigateToSubEntry)
                    .environment(\.managedObjectContext, viewContext)
                    .navigationTitle("Hier muss noch der Titel geändert werden: blogEntry")
            }
        }
        .onAppear() {
            if currentBlogEntry == nil {
                columnVisibility = .all
            }
        }
        .onChange(of: currentBlogEntry) { x in
            if x != nil {
                columnVisibility = .automatic
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            NavigationStack {
                SettingsView()
            }
        }
        .popup(isPresented: $errorService.showError) {
            errorPopup
        } customize: { params in
            params.position(.top)
                .isOpaque(true)
                .animation(.smooth)
                .autohideIn(5)
                .dragToDismiss(true)
                .closeOnTap(true)
                .closeOnTapOutside(true)
                .type(.toast)
        }
    }
    
    private var errorPopup: some View {
        Text(errorService.errorMessage)
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 60, leading: 32, bottom: 16, trailing: 32))
            .frame(maxWidth: .infinity)
            .background(errorService.color)
    }
}

struct MainApplicationView_Previews: PreviewProvider {
    static var previews: some View {
        // prevent crash of preview: https://stackoverflow.com/questions/72242577/fetching-data-in-preview-a-fetch-request-must-have-an-entity-uncaughtexception
        var blogEntry = BlogEntry(context: PreviewData.shared.container.viewContext)
        
        MainApplicationView()
            .environment(\.managedObjectContext, PreviewData.shared.container.viewContext)
            .environmentObject(FefeBlogService(context: PreviewData.shared.container.viewContext))
    }
}
