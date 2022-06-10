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
                sectionBlogEntries
                sectionOther
                sectionLicenses
            }
            .navigationTitle("Settings")
        }
    }
    
    private var sectionApplication: some View {
        Section("Application behaviour") {
            Toggle("Open links in internal browser", isOn: $settings.openUrlsInInternalBrowser)
            Picker("Number of lines in list", selection: $settings.overviewLineLimit) {
                ForEach(1 ..< 5) { lineLimit in
                    Text("\(lineLimit)")
                        .tag(lineLimit)
                }
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
    
    private var sectionBlogEntries: some View {
        Section("Blog entries") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Delete old blog entries", isOn: $settings.regularlyDeleteOldBlogEntries)
                if settings.regularlyDeleteOldBlogEntries {
                    Text("The app stores a copy of the loaded blog entries locally on your device. Blog entries older than half a year will be deleted to save some space. Older entries can always be re-downloaded by scrolling down.")
                        .lineLimit(10)
                        .font(.footnote)
                } else {
                    Text("The app stores a copy of the loaded blog entries locally on your device. Old blog entries will not be deleted.")
                        .font(.footnote)
                }
            }
            if settings.regularlyDeleteOldBlogEntries {
                Toggle("Keep bookmarked blog entries", isOn: $settings.keepBookmarkedBlogEntries)
            }
            Button(action: {
                showClearBookmarksConfirmation = true
            }, label: {
                Text("Reset bookmarks")
            })
            .confirmationDialog("Reset all bookmarks?", isPresented: $showClearBookmarksConfirmation, titleVisibility: .visible) {
                Button("Reset bookmarks", role: .destructive) {
                    CoreDataAccess.shared.resetBookmarks()
                }
            }
            Button(role: .destructive, action: {
                showClearBlogEntriesConfirmation = true
            }, label: {
                Text("Clear all loaded blog entries")
            })
            .confirmationDialog("Permanently erase all loaded blog entries and bookmarks?", isPresented: $showClearBlogEntriesConfirmation, titleVisibility: .visible) {
                Button("Delete all", role: .destructive) {
                    CoreDataAccess.shared.clearBlogEntries()
                }
            }
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
