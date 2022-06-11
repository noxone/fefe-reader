//
//  BlogEntryExtension.swift
//  FefeReader
//
//  Created by Olaf Neumann on 30.05.22.
//

import SwiftUI

extension BlogEntry {
    static let VALID_STATE_NORMAL = "N"
    static let VALID_STATE_TEMPORARY = "T"
    
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
    
    var isTemporary: Bool {
        get {
            return validState == BlogEntry.VALID_STATE_TEMPORARY
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
            FefeBlogService.shared.createUrl(forId: Int(id))
        }
    }
    
    var linkUrls: [URL] {
        get {
            if let content = content {
                return HtmlService.shared.extractLinks(html: content)
            } else {
                return []
            }
        }
    }
}
