//
//  SettingsView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.06.22.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = Settings.shared
    
    @State private var showClearBlogEntriesConfirmation = false
    @State private var showClearBookmarksConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                sectionApplication
                sectionFont
                sectionOther
                sectionDevelopment
                sectionLicenses
            }
            .navigationTitle("Settings")
            .confirmationDialog("Permanently erase all loaded blog entries and bookmarks?", isPresented: $showClearBlogEntriesConfirmation, titleVisibility: .visible) {
                Button("Delete all", role: .destructive) {
                    PersistenceController.shared.clearBlogEntries()
                }
            }
            .confirmationDialog("Reset all bookmarks?", isPresented: $showClearBookmarksConfirmation, titleVisibility: .visible) {
                Button("Delete bookmarks", role: .destructive) {
                    PersistenceController.shared.resetBookmarks()
                }
            }
        }
    }
    
    private var sectionApplication: some View {
        Group {
            Section {
                Toggle("Open links in internal browser", isOn: $settings.openUrlsInInternalBrowser)
                Picker("Number of lines in list", selection: $settings.overviewLineLimit) {
                    ForEach(1 ..< 5) { lineLimit in
                        Text("\(lineLimit)")
                            .tag(lineLimit)
                    }
                }
            } header: {
                Text("Application")
            }
        }
    }
    
    private var sectionOther: some View {
        Section("Feedback") {
            Button(action: {
                UIApplication.shared.open(Settings.issueUrl)
            }, label: {
                Text("Issue tracker")
            })
        }
    }
    
    private var sectionFont: some View {
        Section("Font") {
            HStack {
                Text("Font size: \(settings.fontSize)")
                Spacer()
                Button(action: {
                    settings.fontSize += 1
                    if settings.fontSize < 2 {
                        settings.fontSize = 2
                        // TODO better handling
                    }
                }, label: {
                    Text("+")
                        .frame(width: 20, height: 20)
                })
                .buttonStyle(.bordered)
                Button(action: {
                    settings.fontSize -= 1
                }, label: {
                    Text("-")
                        .frame(width: 20, height: 20)
                })
                .buttonStyle(.bordered)
            }
            Picker("Font", selection: $settings.font) {
                ForEach(Settings.availableFonts, id: \.displayName) { font in
                    Text(font.displayName)
                        .font(font.font)
                        .tag(font)
                }
            }

            // TODO: Add reset button
            /*Button(action: {
                settings.fontSize = Settings.defaultFontSize
            }, label: {
                Text("Reset")
            })*/
        }
    }
    
    private var sectionDevelopment: some View {
        Section("Danger Zone") {
            Button(action: {
                showClearBookmarksConfirmation = true
            }, label: {
                Text("Reset bookmarks")
            })
            Button(role: .destructive, action: {
                showClearBlogEntriesConfirmation = true
            }, label: {
                Text("Clear all loaded blog entries")
            })
        }
    }
    
    private var sectionLicenses: some View {
        Section("Licenses") {
            NavigationLink("View licenses") {
                LicensesView()
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
