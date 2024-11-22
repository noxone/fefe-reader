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
    
    // The blog entry we want to display
    let blogEntry: BlogEntry
    let navigateToEntry: ((BlogEntry) -> ())?
    let navigateToSubEntry: (BlogEntry) -> ()
    @State private var isBookmarked: Bool? = nil
    
    // For controlling the integrated browser
    @State private var action = WebViewAction.idle
    @State private var state = WebViewState.empty
    private let config = WebViewConfig(javaScriptEnabled: false, allowsBackForwardNavigationGestures: false, allowsInlineMediaPlayback: false, mediaTypesRequiringUserActionForPlayback: .all, isScrollEnabled: true, isOpaque: false, backgroundColor: .background)

    // If an external link shall be displayed
    @State private var showExternalContent = false
    @State private var externalUrl: URL = URL(string: "https://blog.fefe.de")!
    
    // If a link shall be shared
    @State private var showShareSheet = false
    @State private var showLinkList = false
    
    // If another blog entry shall be shown
    @State private var showPreparingSubEntry = false
    
    @State private var previousBlogEntry: BlogEntry? = nil
    @State private var nextBlogEntry: BlogEntry? = nil
        
    var body: some View {
        WebView(config: config, action: $action, state: $state, schemeHandlers: ["http": handleHttpLinks(url:), "https": handleHttpLinks(url:)])
            .popup(isPresented: $showLinkList, type: .floater(), position: .bottom, closeOnTap: false, closeOnTapOutside: true) {
                linkListSheet
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        if let navigateToEntry {
                            Button(action: {
                                if let previousBlogEntry {
                                    navigateToEntry(previousBlogEntry)
                                }
                            }, label: {
                                CommonIcons.shared.arrowUp
                            })
                            .disabled(previousBlogEntry == nil)
                            
                            Button(action: {
                                if let nextBlogEntry {
                                    navigateToEntry(nextBlogEntry)
                                }
                            }, label: {
                                CommonIcons.shared.arrowDown
                            })
                            .disabled(nextBlogEntry == nil)
                        }
                        
                        Spacer()
                        
                        if !blogEntry.links.isEmpty {
                            Button(action: {
                                showLinkList.toggle()
                            }, label: {
                                CommonIcons.shared.linkListImage
                            })
                        }
                        
                        Button(action: {
                            showShareSheet = true
                        }, label: {
                            CommonIcons.shared.shareImage
                        })
                    }
                }
            }
        /*
         .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
         .onEnded({ value in
         if value.translation.width < 0 {
         // left
         print("LEFT")
         }
         
         if value.translation.width > 0 {
         // right
         print("RIGHT")
         }
         if value.translation.height < 0 {
         // up
         print("UP")
         }
         
         if value.translation.height > 0 {
         // down
         print("DOWN")
         }
         }))
         */
            .navigationTitle(DateFormatter.localizedString(from: blogEntry.secureDate, dateStyle: .long, timeStyle: .none))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        FefeBlogService.shared.toggleBookmark(for: blogEntry)
                        isBookmarked = blogEntry.isBookmarked
                    }, label: {
                        CommonIcons.shared.bookmarkImage(active: isBookmarked ?? blogEntry.isBookmarked)
                    })
                }
                
                ToolbarItem(placement: .principal) {
                    if showPreparingSubEntry {
                        ProgressView()
                    }
                }
            }
            .onAppear {
                loadStuff(for: blogEntry)
            }
            .sheet(isPresented: $showExternalContent) {
                NavigationStack {
                    BrowserPopupView(url: $externalUrl)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [blogEntry.url.absoluteURL])
            }
            .onChange(of: blogEntry) { newVal in
                loadStuff(for: newVal)
            }
    }
    
    private func loadStuff(for blogEntry: BlogEntry) {
        if let content = blogEntry.content {
            action = .loadHTML(HtmlService.shared.enhance(html: content))
            FefeBlogService.shared.markAsRead(blogEntry)
        } else {
            action = .loadHTML("<i>No content to load.</i>")
        }
        
        previousBlogEntry = DataAccess.shared.getPreviousBlogEntry(from: blogEntry)
        nextBlogEntry = DataAccess.shared.getNextBlogEntry(from: blogEntry)
    }
    
    private func copy(_ link: Link) {
        UIPasteboard.general.url = link.url
        ErrorService.shared.showSuccess(message: "Link in die Zwischenablage kopiert.")
        showLinkList = false
    }
    
    private var linkListSheet: some View {
        MinSizeScrollView {
            VStack(alignment: .leading) {
                ForEach(blogEntry.links) { link in
                    LinkDisplayButton(link: link) { isLongPress in
                        if !isLongPress {
                            copy(link)
                        } else {
                            print("loooooong")
                        }
                    }
                    .contextMenu(menuItems: {
                        Button("URL kopieren") { copy(link) }
                        Button("URL öffnen") {
                            handleHttpLinks(url: link.url)
                            showLinkList = false
                        }
                    })
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(5)
        }
        .background(.ultraThinMaterial)
        .shadow(color: .shadow, radius: 10, x: 0, y: 0)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding()
        .padding(.bottom, 50)
    }
    
    private func handleHttpLinks(url: URL) {
        showPreparingSubEntry = true
        ErrorService.shared.executeShowingError {
            if FefeBlogService.shared.isFefeBlogEntryUrl(url),
               let id = FefeBlogService.shared.getIdFromFefeUrl(url) {
                if let entry = DataAccess.shared.getBlogEntry(withId: id, onlyNormal: true) {
                    navigateToSubEntry(entry)
                    return
                } else if let entry = try await FefeBlogService.shared.loadTemporaryBlogEntryFor(id: id) {
                    navigateToSubEntry(entry)
                    return
                }
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
            BlogEntryDetailView(blogEntry: PreviewData.shared.preview_BlogEntries[0], navigateToEntry: {_ in}, navigateToSubEntry: {_ in})
        }
    }
}
