//
//  BlogEntryDetailView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 31.05.22.
//

import SwiftUI
import SwiftUIWebView

struct BlogEntryDetailView: View {
    private static let dummyBlogEntry = BlogEntry()
    
    @ObservedObject var blogEntry: BlogEntry
    
    @State private var action = WebViewAction.idle
    @State private var state = WebViewState.empty
    
    @State private var showExternalContent = false
    @State private var externalUrl: URL = URL(string: "https://blog.fefe.de")!
    
    @State private var showShareSheet = false
    
    @State private var showPreparingSubEntry = false
    @State private var showSubEntry = false
    @State private var subEntry: BlogEntry = BlogEntryDetailView.dummyBlogEntry
    
    //@State private var urls: [URL] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            let config = WebViewConfig(javaScriptEnabled: false, allowsBackForwardNavigationGestures: false, allowsInlineMediaPlayback: false, mediaTypesRequiringUserActionForPlayback: .all, isScrollEnabled: true, isOpaque: false, backgroundColor: .background)
            WebView(config: config, action: $action, state: $state, schemeHandlers: ["http": handleHttpLinks(url:), "https": handleHttpLinks(url:)])
            NavigationLink(isActive: $showSubEntry, destination: {
                BlogEntryDetailWrapper(blogEntry: $subEntry)
            }, label: {
                EmptyView()
            })
        }
        .navigationTitle(DateFormatter.localizedString(from: blogEntry.secureDate, dateStyle: .long, timeStyle: .none))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    FefeBlogService.shared.toggleBookmark(for: blogEntry)
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
            
            ToolbarItem(placement: .principal) {
                if showPreparingSubEntry {
                    ProgressView()
                }
            }
        }
        .onAppear {
            if let content = blogEntry.content {
                action = .loadHTML(HtmlService.shared.enhance(html: content))
                FefeBlogService.shared.markAsRead(blogEntry)
                
                //urls = blogEntry.linkUrls
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
        showPreparingSubEntry = true
        ErrorService.shared.executeShowingError {
            if FefeBlogService.shared.isFefeBlogEntryUrl(url),
                let id = FefeBlogService.shared.getIdFromFefeUrl(url),
                let entry = try await FefeBlogService.shared.loadTemporaryBlogEntryFor(id: id)
            {
                subEntry = entry
                showSubEntry = true
                return
            }

            if Settings.shared.openUrlsInInternalBrowser {
                externalUrl = url
                showExternalContent = true
            } else {
                UrlService.openUrl(url)
            }
        } andAlwaysDo: {
            showPreparingSubEntry = false
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
