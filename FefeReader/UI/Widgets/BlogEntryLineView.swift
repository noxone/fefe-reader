//
//  BlogEntryLineView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 29.05.22.
//

import SwiftUI
import CoreData

struct BlogEntryRowView: View {
    @State var blogEntry: BlogEntry

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            let teaser = blogEntry.teaser
            let unread = !blogEntry.alreadyRead
            Text(teaser ?? "No teaser")
                .active(teaser == nil, Text.italic)
                .opacity(unread ? 0.6 : 1.0)
                .lineLimit(1)
            Spacer()
            Button(action: {
                FefeBlog.shared.toggleFavourite(blogEntry: blogEntry)
            }, label: {
                Image(systemName: blogEntry.favourite ? "star.fill" : "star")
                    .foregroundColor(Color.yellow)
            })
            
        }
    }
}

struct BlogEntryLineView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BlogEntryRowView(blogEntry: PersistenceController.preview.preview_BlogEntries[0])
            BlogEntryRowView(blogEntry: PersistenceController.preview.preview_BlogEntries[1])
            BlogEntryRowView(blogEntry: PersistenceController.preview.preview_BlogEntries[2])
                .preferredColorScheme(.dark)
            BlogEntryRowView(blogEntry: PersistenceController.preview.preview_BlogEntries[3])
                .preferredColorScheme(.dark)
        }
        .previewLayout(PreviewLayout.fixed(width: 400, height: 50))
    }
}
