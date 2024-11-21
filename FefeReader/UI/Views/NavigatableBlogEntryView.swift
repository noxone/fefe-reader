//
//  NavigatableBlogEntryView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 20.11.24.
//

import SwiftUI

struct NavigatableBlogEntryView<Content: View>: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding private var selectedBlogEntry: BlogEntry?
    
    @ViewBuilder private let content: (Binding<BlogEntry?>) -> Content
    
    init(selectedBlogEntry: Binding<BlogEntry?>, content: @escaping (Binding<BlogEntry?>) -> Content) {
        self._selectedBlogEntry = selectedBlogEntry
        self.content = content
    }
    
    var body: some View {
        NavigationSplitView(sidebar: {
            content($selectedBlogEntry)
        }, detail: {
            if let blogEntry = selectedBlogEntry {
                BlogEntryDetailView(blogEntry: blogEntry)
            } else {
                Text("Kein Blogeintrag zum Lesen ausgewählt.")
            }
        })
    }
}


struct NavigatableBlogEntryView_Previews: PreviewProvider {
    static var previews: some View {
        // prevent crash of preview: https://stackoverflow.com/questions/72242577/fetching-data-in-preview-a-fetch-request-must-have-an-entity-uncaughtexception
        var blogEntry = BlogEntry(context: PreviewData.shared.container.viewContext)
        
        NavigatableBlogEntryView(selectedBlogEntry: .constant(nil)) { binding in
            BlogEntryListView(tabSelection: .constant(.blog))
        }
        .environment(\.managedObjectContext, PreviewData.shared.container.viewContext)
    }
}
