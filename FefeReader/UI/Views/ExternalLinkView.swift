//
//  ExternalLinkView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.06.22.
//

import SwiftUI
import SwiftUIWebView

struct ExternalLinkView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var url: URL
    
    @State private var action = WebViewAction.idle
    @State private var state = WebViewState.empty
    @State private var address = "https://www.google.com"
    
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                let config = WebViewConfig(javaScriptEnabled: true, allowsBackForwardNavigationGestures: true, allowsInlineMediaPlayback: true, mediaTypesRequiringUserActionForPlayback: .all, isScrollEnabled: true, isOpaque: false, backgroundColor: .background)
                WebView(config: config, action: $action, state: $state)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        ExitButtonView()
                            .frame(width: 30, height: 30)
                    })
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(Text("Close"))
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIApplication.shared.open(url)
                    }, label: {
                        Image(systemName: "safari")
                            .imageScale(.large)
                    })
                    .accessibilityLabel(Text("Open in Safari"))
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: {
                        action = .goBack
                    }, label: {
                        Image(systemName: "chevron.left")
                    })
                    .accessibilityLabel(Text("Go Back"))
                    .accessibility(hint: Text("Tap to go back in browser."))
                    .disabled(!state.canGoBack)
                    
                    Button(action: {
                        action = .goForward
                    }, label: {
                        Image(systemName: "chevron.right")
                    })
                    .accessibilityLabel(Text("Go Forward"))
                    .accessibility(hint: Text("Tap to go forward in browser."))
                    .disabled(!state.canGoForward)
                    
                    Spacer()
                    
                    Button(action: {
                        showShareSheet = true
                    }, label: {
                        CommonIcons.shared.shareImage
                    })
                    .accessibilityLabel(Text("Share URL"))
                    .disabled(state.isLoading)

                    Spacer()
                    
                    Button(action: {
                        action = .reload
                    }, label: {
                        Image(systemName: "arrow.clockwise")
                    })
                    .accessibilityLabel(Text("Reload"))
                    .disabled(state.isLoading)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [url])
            }
            .onAppear {
                action = .load(URLRequest(url: url))
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(state.isLoading ? "Loading..." : (state.pageTitle ?? "no page"))
        }
    }
}

struct ExternalLinkView_Previews: PreviewProvider {
    static var previews: some View {
        ExternalLinkView(url: .constant(URL(string: "https://www.apple.com")!))
    }
}
