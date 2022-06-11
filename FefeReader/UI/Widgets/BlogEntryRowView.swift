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
    
    var opacity: CGFloat {
        get {
            if !tintReadEntries {
                return 1.0
            }
            if blogEntry.isRead {
                if blogEntry.updatedSinceLastRead {
                    return 0.8
                } else {
                    return 0.5
                }
            } else {
                return 1.0
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            if showDate {
                HStack {
                    if let date = blogEntry.date {
                        Text("\(date.formatted(date: .long, time: .omitted))")
                            .font(.caption2)
                            .opacity(0.7)
                    }
                }
            }

            HStack(alignment: .center, spacing: 3) {
                let teaser = blogEntry.teaser
                
                Text(teaser ?? "No teaser")
                    .active(teaser == nil, Text.italic)
                    .opacity(opacity)
                    .lineLimit(lineLimit ?? settings.overviewLineLimit)
                Spacer()
                if showBookmarkIcon && blogEntry.isBookmarked {
                    blogEntry.bookmarkImage
                }
            }
            .badge(blogEntry.updatedSinceLastRead ? Text("Updates") : nil)
        }
    }
}

struct BlogEntryRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BlogEntryRowView(blogEntry: PreviewData.shared.preview_BlogEntries[0], showDate: true)
            BlogEntryRowView(blogEntry: PreviewData.shared.preview_BlogEntries[1])
            BlogEntryRowView(blogEntry: PreviewData.shared.preview_BlogEntries[2])
                .preferredColorScheme(.dark)
            BlogEntryRowView(blogEntry: PreviewData.shared.preview_BlogEntries[3])
                .preferredColorScheme(.dark)
        }
        .previewLayout(PreviewLayout.fixed(width: 400, height: 50))
    }
}
