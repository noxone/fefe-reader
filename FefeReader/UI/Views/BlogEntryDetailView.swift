//
//  BlogEntryDetailView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 31.05.22.
//

import SwiftUI
import SwiftUIWebView
import UniformTypeIdentifiers

struct BlogEntryDetailView: View {
    private static let dummyBlogEntry = BlogEntry()
    
    @ObservedObject var blogEntry: BlogEntry
    
    @State private var action = WebViewAction.idle
    @State private var state = WebViewState.empty
    
    @State private var showExternalContent = false
    @State private var externalUrl: URL = URL(string: "https://blog.fefe.de")!
    
    @State private var showShareSheet = false
    @State private var showLinkList = false
    
    @State private var showPreparingSubEntry = false
    @State private var showSubEntry = false
    @State private var subEntry: BlogEntry = BlogEntryDetailView.dummyBlogEntry
    
    private let config = WebViewConfig(javaScriptEnabled: false, allowsBackForwardNavigationGestures: false, allowsInlineMediaPlayback: false, mediaTypesRequiringUserActionForPlayback: .all, isScrollEnabled: true, isOpaque: false, backgroundColor: .background)
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomTrailing) {
                WebView(config: config, action: $action, state: $state, schemeHandlers: ["http": handleHttpLinks(url:), "https": handleHttpLinks(url:)])
                    .popup(isPresented: $showLinkList, type: .floater(), position: .bottom, closeOnTap: false, closeOnTapOutside: true) {
                                    linkListSheet
                                }
                
                HStack(spacing: 10) {
                    if !blogEntry.links.isEmpty {
                        Button(action: {
                            showLinkList.toggle()
                        }, label: {
                            CommonIcons.shared.linkListImage
                                .frame(width: 20, height: 15)
                                .padding()
                        })
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 5))
                    }
                    
                    Button(action: {
                        showShareSheet = true
                    }, label: {
                        CommonIcons.shared.shareImage
                            .frame(width: 20, height: 15)
                            .padding()
                    })
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 5))
                }
                .padding()
            }
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
                if !blogEntry.isTemporary {
                    Button(action: {
                        FefeBlogService.shared.toggleBookmark(for: blogEntry)
                    }, label: {
                        blogEntry.bookmarkImage
                    })
                }
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
            ShareSheet(activityItems: [blogEntry.url.absoluteURL])
        }
    }
    
    private var linkListSheet: some View {
        MinSizeScrollView {
            VStack(alignment: .leading) {
                linkListSheetContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.ultraThinMaterial)
        .shadow(color: .shadow, radius: 10, x: 0, y: 0)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding()
        .padding(.bottom, 50)
    }
    
    private var linkListSheetContent: some View {
        VStack(alignment: .leading) {
            ForEach(blogEntry.links) { link in
                Button(action: {
                    UIPasteboard.general.url = link.url
                    ErrorService.shared.showSuccess(message: "Link in die Zwischenablage kopiert.")
                    showLinkList = false
                }, label: {
                    VStack(alignment: .leading) {
                        if let label = link.label {
                            Text(label)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        Text(link.url.absoluteString)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                })
                .buttonStyle(.bordered)
            }
        }
        .padding(5)
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
            BlogEntryDetailView(blogEntry: PreviewData.shared.preview_BlogEntries[0])
        }
    }
}
