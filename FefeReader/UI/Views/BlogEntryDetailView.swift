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
    
    //@State private var urls: [URL] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            let config = WebViewConfig(javaScriptEnabled: false, allowsBackForwardNavigationGestures: false, allowsInlineMediaPlayback: false, mediaTypesRequiringUserActionForPlayback: .all, isScrollEnabled: true, isOpaque: true, backgroundColor: .white)
            WebView(config: config, action: $action, state: $state, schemeHandlers: ["http": handleHttpLinks(url:), "https": handleHttpLinks(url:)])
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
        }
        .onAppear {
            if let content = blogEntry.content {
                action = .loadHTML(HtmlHelper.shared.enhance(html: content))
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
        print("Handle: ", url)
        if Settings.shared.openUrlsInInternalBrowser {
            externalUrl = url
            showExternalContent = true
        } else {
            UrlService.openUrl(url)
        }
    }
}
struct RowLine<TargetView: View>: View {
    var text: String
    var imageName: String
    var nextView: TargetView
    var body: some View {
        NavigationLink(destination: nextView) {
            HStack {
                Image(systemName: imageName)
                Text(text)
            }
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
