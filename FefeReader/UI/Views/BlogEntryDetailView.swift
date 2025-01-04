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
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var fefeBlog: FefeBlogService
        
    private let persistence = PersistenceController.shared
    
    // The blog entry we want to display
    @ObservedObject var blogEntry: BlogEntry
    let navigateToEntry: ((BlogEntry) -> ())?
    let navigateToSubEntry: (BlogEntry) -> ()
    
    // For controlling the integrated browser
    @State private var action = WebViewAction.idle
    @State private var state = WebViewState.empty
    private let config = WebViewConfig(javaScriptEnabled: false, allowsBackForwardNavigationGestures: false, allowsInlineMediaPlayback: false, mediaTypesRequiringUserActionForPlayback: .all, isScrollEnabled: true, isOpaque: false, backgroundColor: .background)

    // If an external link shall be displayed
    @State private var showExternalContent = false
    @State private var externalUrl: URL = URL(string: "https://blog.fefe.de")!
    
    // If a link shall be shared
    @State private var showLinkList = false
    
    // If another blog entry shall be shown
    @State private var showPreparingSubEntry = false
    
    @State private var previousBlogEntry: BlogEntry? = nil
    @State private var nextBlogEntry: BlogEntry? = nil
    
    private let dragThreshold = 10.0
    @GestureState var dragTranslation = CGSize(width: 0, height: 0)
    
    private var dragToPrevious: Bool {
        dragTranslation.width > 0
    }
    private var dragToNext: Bool {
        dragTranslation.width < 0
    }

    private func getDragImage(systemName: String) -> some View {
        Image(systemName: systemName)
            .resizable()
            .frame(width: 150, height: 150)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10.0).fill(.regularMaterial))
    }
    
    var body: some View {
        ZStack {
            browser
            if dragToNext && nextBlogEntry != nil {
                getDragImage(systemName: "arrow.forward.square")
            }
            if dragToPrevious && previousBlogEntry != nil {
                getDragImage(systemName: "arrow.backward.square")
            }
        }
    }
    
    private var title: String {
        DateFormatter.localizedString(from: blogEntry.secureDate, dateStyle: .long, timeStyle: .none)
    }
    
    private var browser: some View {
        WebView(config: config, action: $action, state: $state, schemeHandlers: ["http": handleHttpLinks(url:), "https": handleHttpLinks(url:)])
            .contextView(isPresented: $showLinkList) {
                linkListSheet
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    HStack {
                        if navigateToEntry != nil {
                            Button(action: goToPreviousBlogEntry, label: {
                                Label("Voriger Blogeintrag", systemImage: CommonIcons.shared.previousBlogEntryImageName)
                            })
                            .adaptiveButtonStyle()
                            .disabled(previousBlogEntry == nil)
                            
                            Button(action: goToNextBlogEntry, label: {
                                Label("Nächster Blogeintrag", systemImage: CommonIcons.shared.nextBlogEntryImageName)
                            })
                            .adaptiveButtonStyle()
                            .disabled(nextBlogEntry == nil)
                        }
                        
                        Spacer()
                        
                        if !blogEntry.links.isEmpty {
                            Button(action: {
                                showLinkList.toggle()
                            }, label: {
                                Label("Links", systemImage: CommonIcons.shared.linkListImageName)
                            })
                            .adaptiveButtonStyle()
                        }
                        
                        ShareLink(item: blogEntry.url.absoluteURL, preview: SharePreview("Beitrag vom \(title) ", image: Image("ShareImage")))
                        .adaptiveButtonStyle()
                    }
                }
            }
            .gesture(DragGesture(minimumDistance: 10, coordinateSpace: .local)
                .updating($dragTranslation) { (value, gestureState, transaction) in
                    transaction.animation = .easeInOut
                    gestureState = value.translation
                }
                .onEnded({ value in
                    if value.translation.width < 0 {
                        goToNextBlogEntry()
                    }
                    if value.translation.width > 0 {
                        goToPreviousBlogEntry()
                    }
                }))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        persistence.toggleBlogEntryBookmark(blogEntry)
                    }, label: {
                        blogEntry.bookmarkImage
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
            .onChange(of: blogEntry) { newVal in
                loadStuff(for: newVal)
            }
    }
    
    private func loadStuff(for blogEntry: BlogEntry) {
        if let content = blogEntry.content {
            action = .loadHTML(HtmlService.shared.enhance(html: content))
            persistence.toggleBlogEntryRead(blogEntry, read: true)
        } else {
            action = .loadHTML("<i>No content to load.</i>")
        }
        
        previousBlogEntry = persistence.getPreviousBlogEntry(from: blogEntry, context: viewContext)
        nextBlogEntry = persistence.getNextBlogEntry(from: blogEntry, context: viewContext)
    }
    
    private func copy(_ link: Link) {
        UIPasteboard.general.url = link.url
        ErrorService.shared.showSuccess(message: "Link in die Zwischenablage kopiert.")
        showLinkList = false
    }
    
    private func goToNextBlogEntry() {
        if let nextBlogEntry {
            navigateToEntry?(nextBlogEntry)
        }
    }
    
    private func goToPreviousBlogEntry() {
        if let previousBlogEntry {
            navigateToEntry?(previousBlogEntry)
        }
    }
    
    private var linkListSheet: some View {
        if #available(iOS 17.0, *) {
            AnyView(
                ScrollView {
                    unframedLinkList
                }
                    .padding(.top)
            )
        } else {
            AnyView(framedLinkList)
        }
    }
    
    private var framedLinkList: some View {
        MinSizeScrollView {
            unframedLinkList
        }
        .background(.ultraThinMaterial)
        .shadow(color: .shadow, radius: 10, x: 0, y: 0)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .padding()
        .padding(.bottom, 50)
    }
    
    private var unframedLinkList: some View {
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
    
    private func handleHttpLinks(url: URL) {
        showPreparingSubEntry = true
        ErrorService.shared.executeShowingError {
            if FefeBlogService.isFefeBlogEntryUrl(url),
               let id = FefeBlogService.getIdFromFefeUrl(url) {
                if let entry = persistence.getBlogEntry(withId: id, context: viewContext) {
                    navigateToSubEntry(entry)
                    return
                } else if let rawEntry = try await fefeBlog.loadRawEntry(forId: id) {
                    let blogEntry = persistence.createBlogEntryAndSave(from: rawEntry, withValidState: .search, context: viewContext)
                    navigateToSubEntry(blogEntry)
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
        NavigationStack {
            BlogEntryDetailView(blogEntry: PreviewData.shared.preview_BlogEntries[0], navigateToEntry: {_ in}, navigateToSubEntry: {_ in})
        }
        .environment(\.managedObjectContext, PreviewData.shared.container.viewContext)
    }
}
