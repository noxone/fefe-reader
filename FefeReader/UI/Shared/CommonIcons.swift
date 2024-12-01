//
//  File.swift
//  FefeReader
//
//  Created by Olaf Neumann on 02.06.22.
//

import SwiftUI

class CommonIcons {
    static let shared = CommonIcons()
    
    let bookmarkColor: Color = .purple
    let bookmarkImageActiveName = "bookmark.fill"
    private let bookmarkImageInactiveName = "bookmark"
    
    private let blogImageName = "list.bullet"
    
    let shareImageName = "square.and.arrow.up"
    
    private let searchImageName = "magnifyingglass"
    
    private let trashImageName = "trash"
    
    private let settingsImageName = "gear"
    
    let linkListImageName = "link.circle"
    
    let previousBlogEntryImageName = "arrow.left"
    
    let nextBlogEntryImageName = "arrow.right"
    
    private let filterUnreadInactiveImageName = "line.3.horizontal.decrease.circle"
    private let filterUnreadActiveImageName = "line.3.horizontal.decrease.circle.fill"
    
    private init() {}
    
    func bookmarkImage(for blogEntry: BlogEntry) -> some View {
        return bookmarkImage(active: blogEntry.isBookmarked)
    }
    
    func bookmarkImage(active: Bool = true) -> some View {
        return Image(systemName: active ? bookmarkImageActiveName : bookmarkImageInactiveName)
            .foregroundColor(bookmarkColor)
    }
    
    var blogImage: Image { Image(systemName: blogImageName) }
    
    var bookmarkImage: Image { Image(systemName: bookmarkImageActiveName) }
    
    var shareImage: Image { Image(systemName: shareImageName) }
    
    var searchImage: Image { Image(systemName: searchImageName) }

    var trashImage: Image { Image(systemName: trashImageName) }
    
    var settingsImage: Image { Image(systemName: settingsImageName) }
    
    var linkListImage: Image { Image(systemName: linkListImageName) }
    
    var previousBlogEntry: Image { Image(systemName: previousBlogEntryImageName) }
    
    var nextBlogEntry: Image { Image(systemName: nextBlogEntryImageName) }
    
    var filterUnreadInactive: Image { Image(systemName: filterUnreadInactiveImageName) }
    
    var filterUnreadActive: Image { Image(systemName: filterUnreadActiveImageName) }
    
    func filterUnread(active: Bool) -> Image {
        if active {
            return filterUnreadActive
        } else {
            return filterUnreadInactive
        }
    }
}
