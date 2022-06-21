//
//  TabbedBlogView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.06.22.
//

import SwiftUI

struct TabbedBlogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var tabSelection: TabItem = .blog
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont(name: "Allison", size: 55)!]
    }
    
    var body: some View {
        TabView(selection: $tabSelection) {
            BlogEntryListView(tabSelection: $tabSelection)
            .environment(\.managedObjectContext, viewContext)
            .tabItem {
                CommonIcons.shared.blogImage
                Text("Blog")
            }
            .tag(TabItem.blog)
            
            BookmarkListView()
            .environment(\.managedObjectContext, viewContext)
            .tabItem {
                CommonIcons.shared.bookmarkImage
                Text("Lesezeichen")
            }
            .tag(TabItem.bookmarks)
            
            SettingsView()
            .tabItem {
                CommonIcons.shared.settingsImage
                Text("Einstellungen")
            }
            .tag(TabItem.settings)
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
        TabbedBlogView()
            .environment(\.managedObjectContext, PreviewData.shared.container.viewContext)
    }
}
