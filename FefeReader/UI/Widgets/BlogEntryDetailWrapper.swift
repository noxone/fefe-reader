//
//  BlogEntryDetailWrapper.swift
//  FefeReader
//
//  Created by Olaf Neumann on 08.06.22.
//

import SwiftUI

struct BlogEntryDetailWrapper: View {
    @Binding var blogEntry: BlogEntry
    
    var body: some View {
        BlogEntryDetailView(blogEntry: blogEntry)
    }
}

struct BlogEntryDetailWrapper_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BlogEntryDetailWrapper(blogEntry: .constant(PersistenceController.preview.preview_BlogEntries[2]))
        }
    }
}
