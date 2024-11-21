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
//        if #available(iOS 18, macOS 15, tvOS 18, watchOS 10, visionOS 1, *) {
        TabView(selection: $tabSelection) {
            tab("Blog", image: CommonIcons.shared.blogImage, tag: TabItem.blog) {
                blogItem
            }
            tab("Lesezeichen", image: CommonIcons.shared.bookmarkImage, tag: TabItem.bookmarks) {
                bookmarksItem
            }
            tab("Einstellungen", image: CommonIcons.shared.settingsImage, tag: TabItem.settings) {
                settingsItem
            }
        }
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
        BlogEntryListView(tabSelection: $tabSelection)
            .environment(\.managedObjectContext, viewContext)
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
