//
//  BlogEntryExtension.swift
//  FefeReader
//
//  Created by Olaf Neumann on 30.05.22.
//

import SwiftUI

extension BlogEntry {
    var isRead: Bool {
        get {
            return readTimestamp != nil
        }
    }
    
    var isBookmarked: Bool {
        get {
            return bookmarkDate != nil
        }
    }
    
    var secureDate: Date {
        get {
            return date ?? Date()
        }
    }
    
    func teaserPrefix(withMaximumLength length: Int) -> String? {
        guard let teaser = teaser else { return nil }
        
        let addEllipsis = teaser.count > length
        return String(teaser[..<teaser.index(teaser.startIndex, offsetBy: min(length, teaser.count))]) + (addEllipsis ? "..." : "")
    }
    
    var bookmarkImage: some View {
        get {
            CommonIcons.shared.bookmarkImage(for: self)
        }
    }
    
    var url: URL {
        get {
            FefeBlog.shared.createUrl(forId: Int(id))
        }
    }
    
    var linkUrls: [URL] {
        get {
            if let content = content {
                return HtmlHelper.shared.extractLinks(html: content)
            } else {
                return []
            }
        }
    }
}
