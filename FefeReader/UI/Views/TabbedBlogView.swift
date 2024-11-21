//
//  TabbedBlogView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.06.22.
//

import SwiftUI

struct TabbedBlogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedBlogEntry: BlogEntry? = nil
    @State private var tabSelection: TabItem = .blog
    
    @State private var showOnlyBookmarks: Bool = false
    
    @State private var rerender: Bool = false
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont(name: "Allison", size: 55)!]
    }
    
    var body: some View {
        blogItem
    }
    
    private func tab<Content, V>(_ title: LocalizedStringKey, image: Image, tag: V, @ViewBuilder content: () -> Content) -> some View where Content : View, V : Hashable {
        content()
            .tabItem {
                image
                Text(title)
            }
            .tag(tag)
    }
    
    private var blogItem: some View {
        NavigationSplitView {
            BlogEntryListView(selectedBlogEntry: $selectedBlogEntry, tabSelection: $tabSelection)
                .environment(\.managedObjectContext, viewContext)
                /*.toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            showOnlyBookmarks.toggle()
                        }, label: {
                            CommonIcons.shared.bookmarkImage(active: showOnlyBookmarks)
                        })
                    }
                    
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            
                        }, label: {
                            CommonIcons.shared.settingsImage
                        })
                    }
                }*/
        } detail: {
            if let blogEntry = selectedBlogEntry {
                BlogEntryDetailView(blogEntry: blogEntry)
            } else {
                Text("Kein Blogeintrag zum Lesen ausgewählt.")
            }
        }
        
    }
    
    private var bookmarksItem: some View {
        BookmarkListView()
            .environment(\.managedObjectContext, viewContext)
    }
    
    private var settingsItem: some View {
        NavigationStack {
            SettingsView()
        }
    }
    
    enum TabItem : Hashable {
        case blog
        case bookmarks
        case settings
    }

}

struct TabbedBlogView_Previews: PreviewProvider {
    static var previews: some View {
        // prevent crash of preview: https://stackoverflow.com/questions/72242577/fetching-data-in-preview-a-fetch-request-must-have-an-entity-uncaughtexception
        var blogEntry = BlogEntry(context: PreviewData.shared.container.viewContext)
        
        TabbedBlogView()
            .environment(\.managedObjectContext, PreviewData.shared.container.viewContext)
    }
}
