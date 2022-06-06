//
//  BlogEntryDetailView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 31.05.22.
//

import SwiftUI
import SwiftUIWebView

struct BlogEntryDetailView: View {
    @ObservedObject var blogEntry: BlogEntry
    
    @State private var action = WebViewAction.idle
    @State private var state = WebViewState.empty
    
    @State private var showExternalContent = false
    @State private var externalUrl: URL = URL(string: "https://blog.fefe.de")!
    
    @State private var showShareSheet = false
    
    var dateString: String {
        get {
            if let date = blogEntry.date {
                return DateFormatter.localizedString(from: date, dateStyle: .long, timeStyle: .none)
            } else {
                return "0-0-0"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            let config = WebViewConfig(javaScriptEnabled: false, allowsBackForwardNavigationGestures: false, allowsInlineMediaPlayback: false, mediaTypesRequiringUserActionForPlayback: .all, isScrollEnabled: true, isOpaque: true, backgroundColor: .white)
            WebView(config: config, action: $action, state: $state, schemeHandlers: ["http": handleHttpLinks(url:), "https": handleHttpLinks(url:)])
        }
        .navigationTitle(dateString)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    FefeBlog.shared.toggleBookmark(for: blogEntry)
                }, label: {
                    blogEntry.bookmarkImage
                })
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showShareSheet = true
                }, label: {
                    CommonIcons.shared.shareImage
                })
            }
        }
        .onAppear {
            if let content = blogEntry.content {
                action = .loadHTML(HtmlEnhancer.shared.enhance(html: content))
                FefeBlog.shared.markAsRead(blogEntry)
                PersistenceController.shared.save()
            } else {
                action = .loadHTML("<i>No content to load.</i>")
            }
        }
        .sheet(isPresented: $showExternalContent) {
            ExternalLinkView(url: $externalUrl)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [blogEntry.url])
        }
    }
    
    private func handleHttpLinks(url: URL) {
        if Settings.shared.openUrlsInInternalBrowser {
            externalUrl = url
            showExternalContent = true
        } else {
            UIApplication.shared.open(url)
        }
    }
}

struct BlogEntryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BlogEntryDetailView(blogEntry: PersistenceController.preview.preview_BlogEntries[0])
        }
    }
}
