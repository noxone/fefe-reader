//
//  TabbedBlogView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.06.22.
//

import SwiftUI

struct TabbedBlogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            BlogEntryListView()
            .environment(\.managedObjectContext, viewContext)
            .tabItem {
                CommonIcons.shared.blogImage
                Text("Blog")
            }
            
            BookmarkListView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    CommonIcons.shared.bookmarkImage
                    Text("Bookmarks")
                }
            
            /*CommonIcons.shared.searchImage
                .tabItem {
                    CommonIcons.shared.searchImage
                    Text("Search")
                }*/
            
            /*UpdateFetchListView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Image(systemName: "circle")
                    Text("Updates")
                }*/
            
            SettingsView()
            .tabItem {
                CommonIcons.shared.settingsImage
                Text("Settings")
            }
        }
    }
}

struct TabbedBlogView_Previews: PreviewProvider {
    static var previews: some View {
        TabbedBlogView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
