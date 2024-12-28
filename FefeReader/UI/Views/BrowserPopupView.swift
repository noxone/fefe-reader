//
//  ExternalLinkView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.06.22.
//

import SwiftUI
import SwiftUIWebView

struct BrowserPopupView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var url: URL
    
    @State private var action = WebViewAction.idle
    @State private var state = WebViewState.empty
    @State private var address = "https://www.google.com"
    
    private let config = WebViewConfig(javaScriptEnabled: true, allowsBackForwardNavigationGestures: true, allowsInlineMediaPlayback: true, mediaTypesRequiringUserActionForPlayback: .all, isScrollEnabled: true, isOpaque: false, backgroundColor: .background)
    
    var body: some View {
        VStack {
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
                .accessibilityLabel(Text("Schließen"))
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    UIApplication.shared.open(url)
                }, label: {
                    Image(systemName: "safari")
                        .imageScale(.large)
                })
                .accessibilityLabel(Text("Im Browser öffnen"))
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    action = .goBack
                }, label: {
                    Image(systemName: "chevron.left")
                })
                .accessibilityLabel(Text("Zurück"))
                .accessibility(hint: Text("Drücken, um im Browser zurückzugehen."))
                .disabled(!state.canGoBack)
                
                Button(action: {
                    action = .goForward
                }, label: {
                    Image(systemName: "chevron.right")
                })
                .accessibilityLabel(Text("Vorwärst"))
                .accessibility(hint: Text("Drücken, um im Browser vorwärts zu gehen."))
                .disabled(!state.canGoForward)
                
                Spacer()
                
                ShareLink(item: url)
                .accessibilityLabel(Text("URL teilen"))
                .disabled(state.isLoading)
                
                Spacer()
                
                Button(action: {
                    action = .reload
                }, label: {
                    Image(systemName: "arrow.clockwise")
                })
                .accessibilityLabel(Text("Neu laden"))
                .disabled(state.isLoading)
            }
        }
        .onAppear {
            action = .load(URLRequest(url: url))
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(state.isLoading ? "Lade..." : (state.pageTitle ?? "keine Seite geladen"))
    }
}

struct BrowserPopupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BrowserPopupView(url: .constant(URL(string: "https://www.apple.com")!))
        }
    }
}
