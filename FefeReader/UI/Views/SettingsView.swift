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
    @State private var showClearReadConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                sectionApplication
                sectionFont
                sectionBlog
                sectionBlogEntries
                sectionOther
                sectionLicenses
            }
            .navigationTitle("Einstellungen")
        }
    }
    
    private var sectionBlog: some View {
        Section("Blog") {
            Button(FefeBlogService.baseUrl.absoluteString) {
                UrlService.openUrl(FefeBlogService.baseUrl)
            }
            Button("FAQ") {
                UrlService.openUrl(URL(string: "https://blog.fefe.de/faq.html")!)
            }
            Button("Email an Fefe") {
                UrlService.openUrl(URL(string: "mailto:felix-bloginput@fefe.de")!)
            }
            Button("Podcast 'Alternativlos'") {
                UrlService.openUrl(URL(string: "https://podcasts.apple.com/de/podcast/alternativlos/id384290007")!)
            }
        }
    }
    
    private var sectionApplication: some View {
        Section("Verhalten") {
            Toggle("Links im internen Browser öffnen", isOn: $settings.openUrlsInInternalBrowser)
            Picker("Anzahl Vorschauzeilen in der Liste", selection: $settings.overviewLineLimit) {
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
        Section("Schrift") {
            HStack {
                Text("Schriftgröße: \(settings.fontSize)")
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
            Picker("Schriftart", selection: $settings.font) {
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
        Section("Blogeinträge") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Alte Blogeinträge löschen", isOn: $settings.regularlyDeleteOldBlogEntries)
                if settings.regularlyDeleteOldBlogEntries {
                    Text("Die App speichert eine Kopie der Blogeinträge lokal auf Deinem Gerät. Blogeinträge, die älter als ein Jahr sind, werden vom Gerät gelöscht, um Speicherplatz zu sparen. Ältere Einträge können jederzeit neu heruntergeladen werden, indem weiter nach unten gescrollt wird.")
                        .lineLimit(10)
                        .font(.footnote)
                } else {
                    Text("Die App speichert eine Kopie der Blogeinträge lokal auf Deinem Gerät. Alte Einträge werden nicht gelöscht.")
                        .font(.footnote)
                }
            }
            if settings.regularlyDeleteOldBlogEntries {
                Toggle("Lesezeichen dennoch behalten", isOn: $settings.keepBookmarkedBlogEntries)
            }
            Button(action: {
                showClearBookmarksConfirmation = true
            }, label: {
                Text("Lesezeichen zurücksetzen")
            })
            .confirmationDialog("Alle Lesezeichen zurücksetzen?", isPresented: $showClearBookmarksConfirmation, titleVisibility: .visible) {
                Button("Lesezeichen zurücksetzen", role: .destructive) {
                    DataAccess.shared.resetBookmarks()
                }
            }
            Button(action: {
                showClearReadConfirmation = true
            }, label: {
                Text("Gelesene Einträge zurücksetzen")
            })
            .confirmationDialog("Alle gelesenen Einträge zurücksetzen?", isPresented: $showClearReadConfirmation, titleVisibility: .visible) {
                Button("Gelesene Einträge zurücksetzen", role: .destructive) {
                    DataAccess.shared.resetRead()
                }
            }
            Button(role: .destructive, action: {
                showClearBlogEntriesConfirmation = true
            }, label: {
                Text("Geladenen Blogeinträge löschen")
            })
            .confirmationDialog("Alle geladenen Blogeinträge und Lesezeichen vom Gerät entfernen?", isPresented: $showClearBlogEntriesConfirmation, titleVisibility: .visible) {
                Button("Alles löschen", role: .destructive) {
                    DataAccess.shared.clearBlogEntries()
                }
            }
        }
    }
    
    private var sectionLicenses: some View {
        Section("Lizenzen") {
            NavigationLink("Lizenzen ansehen") {
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
