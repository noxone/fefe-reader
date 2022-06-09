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
    
    private let shareImageName = "square.and.arrow.up"
    
    private let searchImageName = "magnifyingglass"
    
    private let trashImageName = "trash"
    
    private let settingsImageName = "gear"
    
    private init() {
    }
    
    func bookmarkImage(for blogEntry: BlogEntry) -> some View {
        return bookmarkImage(active: blogEntry.isBookmarked)
    }
    
    func bookmarkImage(active: Bool = true) -> some View {
        return Image(systemName: active ? bookmarkImageActiveName : bookmarkImageInactiveName)
            .foregroundColor(bookmarkColor)
    }
    
    var blogImage: Image {
        get {
            Image(systemName: blogImageName)
        }
    }
    
    var bookmarkImage: Image {
        get {
            Image(systemName: bookmarkImageActiveName)
        }
    }
    
    var shareImage: Image {
        get {
            Image(systemName: shareImageName)
        }
    }
    
    var searchImage: Image {
        get {
            Image(systemName: searchImageName)
        }
    }
    
    var trashImage: Image {
        get {
            Image(systemName: trashImageName)
        }
    }
    
    var settingsImage: Image {
        get {
            Image(systemName: settingsImageName)
        }
    }
}
