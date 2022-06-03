//
//  BlogEntryExtension.swift
//  FefeReader
//
//  Created by Olaf Neumann on 30.05.22.
//

import SwiftUI

extension BlogEntry {
    var alreadyRead: Bool {
        get {
            return readTimestamp == nil
        }
    }
    
    var secureDate: Date {
        get {
            return date ?? Date()
        }
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
}
