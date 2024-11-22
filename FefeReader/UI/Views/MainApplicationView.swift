//
//  TabbedBlogView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.06.22.
//

import SwiftUI

struct MainApplicationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var currentBlogEntry: BlogEntry?
    @State private var subBlogEntries = [BlogEntry]()
    
    @State private var showSettingsSheet: Bool = false
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont(name: "Allison", size: 55)!]
    }
    
    var body: some View {
        NavigationSplitView {
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
            let navigateToSubEntry: (BlogEntry) -> Void = { subBlogEntries.append($0) }
            NavigationStack(path: $subBlogEntries) {
                if let currentBlogEntry {
                    BlogEntryDetailView(blogEntry: currentBlogEntry, navigateToSubEntry: navigateToSubEntry)
                } else {
                    Text("Kein Blogeintrag zum Lesen ausgewählt.")
                }
            }
            .navigationDestination(for: BlogEntry.self) { blogEntry in
                BlogEntryDetailView(blogEntry: blogEntry, navigateToSubEntry: navigateToSubEntry)
                    .navigationTitle("Hier muss noch der Titel geändert werden: blogEntry")
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            settingsItem
        }
    }
    
    private var settingsItem: some View {
        NavigationStack {
            SettingsView()
        }
    }
}

struct TabbedBlogView_Previews: PreviewProvider {
    static var previews: some View {
        // prevent crash of preview: https://stackoverflow.com/questions/72242577/fetching-data-in-preview-a-fetch-request-must-have-an-entity-uncaughtexception
        var blogEntry = BlogEntry(context: PreviewData.shared.container.viewContext)
        
        MainApplicationView()
            .environment(\.managedObjectContext, PreviewData.shared.container.viewContext)
    }
}
