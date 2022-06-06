//
//  BlogEntryLineView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 29.05.22.
//

import SwiftUI
import CoreData

struct BlogEntryRowView: View {
    @ObservedObject var blogEntry: BlogEntry
    @ObservedObject private var settings = Settings.shared
    
    var showDate = false
    var tintReadEntries = true
    var showBookmarkIcon = true
    
    var lineLimit: Int? = nil

    var body: some View {
        VStack(alignment: .leading) {
            if showDate {
                HStack {
                    if let date = blogEntry.date {
                        Text("\(date.formatted(date: .long, time: .omitted))")
                            .font(.caption2)
                    }
                }
            }

            HStack(alignment: .center, spacing: 3) {
                let teaser = blogEntry.teaser
                let unread = !blogEntry.alreadyRead
                
                Text(teaser ?? "No teaser")
                    .active(teaser == nil, Text.italic)
                    .opacity(tintReadEntries && unread ? 0.5 : 1.0)
                    .lineLimit(lineLimit ?? settings.overviewLineLimit)
                Spacer()
                if showBookmarkIcon && blogEntry.favourite {
                    blogEntry.bookmarkImage
                }
            }
        }
    }
}

struct BlogEntryRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BlogEntryRowView(blogEntry: PersistenceController.preview.preview_BlogEntries[0], showDate: true)
            BlogEntryRowView(blogEntry: PersistenceController.preview.preview_BlogEntries[1])
            BlogEntryRowView(blogEntry: PersistenceController.preview.preview_BlogEntries[2])
                .preferredColorScheme(.dark)
            BlogEntryRowView(blogEntry: PersistenceController.preview.preview_BlogEntries[3])
                .preferredColorScheme(.dark)
        }
        .previewLayout(PreviewLayout.fixed(width: 400, height: 50))
    }
}
