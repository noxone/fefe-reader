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
    
    private let shareImageName = "square.and.arrow.up"
    
    private let searchImageName = "magnifyingglass"
    
    private let trashImageName = "trash"
    
    private init() {
    }
    
    func bookmarkImage(for blogEntry: BlogEntry) -> some View {
        return bookmarkImage(active: blogEntry.favourite)
    }
    
    func bookmarkImage(active: Bool = true) -> some View {
        return Image(systemName: active ? bookmarkImageActiveName : bookmarkImageInactiveName)
            .foregroundColor(bookmarkColor)
    }
    
    var shareImage: some View {
        get {
            Image(systemName: shareImageName)
        }
    }
    
    var searchImage: some View {
        get {
            Image(systemName: searchImageName)
        }
    }
    
    var trashImage: some View {
        get {
            Image(systemName: trashImageName)
        }
    }
}
